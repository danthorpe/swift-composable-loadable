import ComposableArchitecture
import Foundation

// MARK: - Public API

extension Reducer where State: Sendable {

  /// Integrate a Loadable child domain with a generic Request type
  public func loadable<
    ChildState: Sendable,
    ChildAction,
    Child: Reducer,
    Request: Sendable
  >(
    _ toLoadableState: WritableKeyPath<State, LoadableState<Request, ChildState>>,
    action toLoadingAction: CaseKeyPath<Action, LoadingAction<Request, ChildState, ChildAction>>,
    @ReducerBuilder<ChildState, ChildAction> child: () -> Child,
    load: @escaping @Sendable (Request, State) async throws -> ChildState,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> some ReducerOf<Self> where Child.State: Sendable, ChildState == Child.State, ChildAction == Child.Action {
    loadable(
      fileID: fileID,
      line: line,
      state: toLoadableState,
      action: toLoadingAction,
      client: LoadingClient(load: load),
      child: child
    )
  }

  /// Integrate a Loadable child domain which does not require a Request type
  public func loadable<
    ChildState: Sendable,
    ChildAction,
    Child: Reducer
  >(
    _ toLoadableState: WritableKeyPath<State, LoadableState<EmptyLoadRequest, ChildState>>,
    action toLoadingAction: CaseKeyPath<
      Action, LoadingAction<EmptyLoadRequest, ChildState, ChildAction>
    >,
    @ReducerBuilder<ChildState, ChildAction> child: () -> Child,
    load: @escaping @Sendable (State) async throws -> ChildState,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> some ReducerOf<Self> where Child.State: Sendable, ChildState == Child.State, ChildAction == Child.Action {
    loadable(
      fileID: fileID,
      line: line,
      state: toLoadableState,
      action: toLoadingAction,
      client: LoadingClient(load: load),
      child: child
    )
  }

  /// Integrate some LoadableState which does not require a child domain
  public func loadable<
    ChildState: Sendable,
    Request: Sendable
  >(
    _ toLoadableState: WritableKeyPath<State, LoadableState<Request, ChildState>>,
    action toLoadingAction: CaseKeyPath<Action, LoadingAction<Request, ChildState, NoLoadingAction>>,
    load: @escaping @Sendable (Request, State) async throws -> ChildState,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> some ReducerOf<Self> {
    LoadingReducer(
      parent: self,
      child: EmptyReducer(),
      toLoadableState: toLoadableState,
      toLoadingAction: toLoadingAction,
      client: LoadingClient(load: load),
      fileID: fileID,
      line: line
    )
  }
}

// MARK: - Internal API

extension Reducer where State: Sendable {

  fileprivate func loadable<
    Child: Reducer,
    Request: Sendable,
    Client: LoadableClient<Request, State, Child.State>
  >(
    fileID: StaticString,
    line: UInt,
    state toLoadableState: WritableKeyPath<State, LoadableState<Request, Child.State>>,
    action toLoadingAction: CaseKeyPath<Action, LoadingAction<Request, Child.State, Child.Action>>,
    client: Client,
    @ReducerBuilder<Child.State, Child.Action> child: () -> Child
  ) -> LoadingReducer<Self, Child, Request, Client> where Client.State: Sendable {
    LoadingReducer(
      parent: self,
      child: child(),
      toLoadableState: toLoadableState,
      toLoadingAction: toLoadingAction,
      client: client,
      fileID: fileID,
      line: line
    )
  }
}

// MARK: - Loading Reducer

private struct LoadingReducer<
  Parent: Reducer,
  Child: Reducer,
  Request: Sendable,
  Client: LoadableClient<Request, Parent.State, Child.State>
>: Reducer where Child.State: Sendable {

  typealias State = Parent.State
  typealias Action = Parent.Action
  typealias ThisLoadableState = LoadableState<Request, Child.State>
  typealias ThisLoadingAction = LoadingAction<Request, Child.State, Child.Action>

  @usableFromInline
  let parent: Parent

  @usableFromInline
  let child: Child

  @usableFromInline
  let toLoadableState: WritableKeyPath<Parent.State, ThisLoadableState>

  @usableFromInline
  let toLoadingAction: CaseKeyPath<Parent.Action, ThisLoadingAction>

  @usableFromInline
  let client: Client

  @usableFromInline
  let fileID: StaticString

  @usableFromInline
  let line: UInt

  private let toChildState: WritableKeyPath<Parent.State, Child.State?>
  private let toChildAction: CaseKeyPath<Parent.Action, Child.Action>

  @usableFromInline
  init(
    parent: Parent,
    child: Child,
    toLoadableState: WritableKeyPath<Parent.State, ThisLoadableState>,
    toLoadingAction: CaseKeyPath<Parent.Action, ThisLoadingAction>,
    client: Client,
    fileID: StaticString,
    line: UInt
  ) {
    self.parent = parent
    self.child = child
    self.toLoadableState = toLoadableState
    self.toLoadingAction = toLoadingAction
    self.client = client
    self.fileID = fileID
    self.line = line
    self.toChildState = toLoadableState.appending(path: \.wrappedValue)
    self.toChildAction = toLoadingAction.appending(path: \.loaded)
  }

  struct CancelID: Hashable {}

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    let parentState = UncheckedSendable(state)
    return CombineReducers {
      Scope(state: toLoadableState, action: toLoadingAction) {
        Reduce { loadableState, loadingAction in

          func send(refresh: Bool, _ request: Request) -> Effect<ThisLoadingAction> {
            loadableState.becomeActive(request)
            return
              .run { [load = client.load] send in
                let value = try await load(request, parentState.value)
                await send(.finished(request, didRefresh: refresh, .success(value)))
              } catch: { error, send in
                await send(.finished(request, didRefresh: refresh, .failure(error)))
              }
              .cancellable(id: CancelID(), cancelInFlight: true)
          }

          switch loadingAction {
          case .cancel:
            loadableState.cancel()
            return .cancel(id: CancelID())
          case let .finished(request, _, taskResult):
            loadableState.finish(request, result: Result(taskResult))
            return .none
          case let .load(request):
            return send(refresh: false, request)
          case .refresh:
            guard let request = loadableState.request else { return .none }
            return send(refresh: true, request)
          case .loaded:
            return .none
          }
        }
      }
      .ifLet(toChildState, action: toChildAction) {
        child
      }

      // Run the parent reducer
      parent

    }
    .reduce(into: &state, action: action)
  }
}
