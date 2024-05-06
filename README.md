# swift-composable-loadable

[![CI/CD](https://github.com/danthorpe/swift-composable-loadable/actions/workflows/main.yml/badge.svg)](https://github.com/danthorpe/swift-composable-loadable/actions/workflows/main.yml)

A Swift Composable Architecture component for loadable features.

## Basics

If you make use of [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) (TCA) in your application, this little library will allow you incorporate _asynchronous loading_ of state in your features. Lets assume that the application has a feature which must load some data to show to the user. When we use TCA, we would model this data as the `State` of a feature, for example:

```swift
@Reducer
struct WelcomeFeature {
  struct State {
    let message: String // Load from the server
  }
  // ...
}
````

Let's assume in the above `WelcomeFeature`, that the `message` property of the state will be loaded from our server to show a different message when the app starts. In our app's feature, we could achieve this using `@LoadableState`. First, we can conform the state to `Loadable`,

```swift
extension WelcomeFeature.State: Loadable {
  typealias Request = EmptyLoadRequest
}
```

Then in `AppFeature` we can compose the `WelcomeFeature`.

```swift
@Reducer
struct AppFeature {
  struct State {
    @LoadableStateOf<WelcomeFeature> var welcome
  }
  enum Action {
    case welcome(LoadingActionOf<WelcomeFeature>)
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // main app feature logic
    }
    .loadable(\.$welcome, action: \.welcome) {
      WelcomeFeature()
    } load: { state in
      WelcomeFeature.State(message: try await fetchWelcomeMessageFromServer())
    }
  }
}
```

## Custom Request Types

In the above example, the load function did not require any inputs. Essentially, it has the shape, `() async throws -> Value`. In many cases however, it is necessary to provide an input which we call a _request_, i.e. `(Request) async throws -> Value`. To do this, in the conformance of `Loadable`, we can specify the `Request` type.

```swift
extension WelcomeFeature.State: Loadable {
  typealias Request = WelcomeMessageRequest
}
```

In this scenario, the `.loadable()` reducer modifier will be enriched with the request, like this:

```swift
struct AppFeature {
  // ...
  var body: some ReducerOf<Self> {
    // ...
    .loadable(\.$welcome, action: \.welcome) {
      WelcomeFeature()
    } load: { request, state in
      WelcomeFeature.State(
        message: try await fetchWelcomeMessage(with: request)
      )
    }
  }
}
```

## SwiftUI View Integration

In order to trigger loading, all that is needed is to call the `.load()` action. However, it is common to load content immediately in a view, and for this scenario, there is a provided SwiftUI View, which makes it easy to load the feature when it appears.

```swift
struct AppView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    LoadingView(
      loadOnAppear: store.scope(state: \.$welcome, action: \.welcome)
    ) { store in
      Text(store.message) // the welcome message
    } onError: { error, request in
      Text("Unable to display welcome message, error: \(error.localizedDescription")
    } onActive: { request in
      ProgressView()
    }
  }
}
```

## Different Requests

In some cases, it is not desirably to couple the `Request` type to the `State` that is loaded. For example, you might need to drive the same "list of results" feature from different requests. To do this, it is possible to specify the `Request` type directly on `@LoadableState`, e.g.

```swift
@Reducer
struct AppFeature {
  struct State {
    @LoadableStateWith<String, WelcomeFeature> var welcome
  }
  enum Action {
    case welcome(LoadingActionWith<String, WelcomeFeature>)
  }
  // ... etc
}
```
In the example above, it is not required to conform `WelcomeFeature.State` to `Loadable`, instead we can specify the `Request` type, in this case `String` in the parent feature.

When the `Request` is not `EmptyLoadRequest`, the loading view will require a different initialiser to the one above. In this case, you'll need to provide the original request, for example:

```swift
struct AppView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    LoadingView(
      store.scope(state: \.$welcome, action: \.welcome)
    ) { store in
      Text(store.message) // the welcome message
    } onError: { error, request in
      Text("Unable to display welcome message, error: \(error.localizedDescription")
    } onActive: { request in
      ProgressView()
    } onAppear: {
      store.send(.welcome(.load("Welcome Message Request")))
    }
  }
}
```
