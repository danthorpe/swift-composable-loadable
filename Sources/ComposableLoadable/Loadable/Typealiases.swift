import ComposableArchitecture

// MARK: - Typealias Conveniences

public typealias LoadableStateWith<Request, R: Reducer> = LoadableState<
  Request, R.State
>

public typealias LoadableStateOf<R: Reducer> = LoadableStateWith<
  R.State.Request, R
> where R.State: Loadable

public typealias LoadingActionWith<Request, R: Reducer> = LoadingAction<
  Request, R.State, R.Action
>

public typealias LoadingActionOf<R: Reducer> = LoadingActionWith<
  R.State.Request, R
> where R.State: Loadable

public typealias LoadableStore<Request, State, Action> = Store<
  LoadableState<Request, State>, LoadingAction<Request, State, Action>
>

public typealias LoadableStoreWith<Request, R: Reducer> = LoadableStore<
  Request, R.State, R.Action
>

public typealias LoadableStoreOf<R: Reducer> = LoadableStoreWith<
  R.State.Request, R
> where R.State: Loadable

public typealias LoadedValueStore<Request, State, Action> = Store<
  LoadedValue<Request, State>, LoadingAction<Request, State, Action>
>

public typealias LoadedValueStoreWith<Request, R: Reducer> = LoadedValueStore<
  Request, R.State, R.Action
>

public typealias LoadedFailureStore<Request, Failure: Error, State, Action> = Store<
  LoadedFailure<Request, Failure>, LoadingAction<Request, State, Action>
>

public typealias LoadedFailureStoreWith<Request, Failure: Error, R: Reducer> = LoadedFailureStore<
  Request, Failure, R.State, R.Action
>
