import ComposableArchitecture

// MARK: - Typealias Conveniences

public typealias LoadableStateWith<Request, R: Reducer> = LoadableState<
  Request, R.State
>

public typealias LoadingActionWith<Request, R: Reducer> = LoadingAction<
  Request, R.State, R.Action
>

public typealias LoadableStoreWith<Request, R: Reducer> = Store<
  LoadableStateWith<Request, R>, LoadingActionWith<Request, R>
>

public typealias LoadedValueStoreWith<Request, R: Reducer> = Store<
  LoadedValue<Request, R.State>, LoadingActionWith<Request, R>
>

public typealias LoadedFailureStoreWith<Request, Failure: Error, R: Reducer> = Store<
  LoadedFailure<Request, Failure>, LoadingActionWith<Request, R>
>
