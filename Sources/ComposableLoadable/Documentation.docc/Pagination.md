# Pagination

When an API supports _pagination_, we mean that its response is a subset of items, but with a cursor to load the next "page" of items.

## Overview

Most applications which make use of an API to load a set of items because it cannot return all available items in a single request. To load more items, typically the application makes another request using a "pagination cursor". This can go on indefinitely until all of the items have been loaded, and the API returns a nil pagination cursor.

To that end this library contains a TCA compatible feature to support "infinite" scrolling and paginating items.

### Basics

For example lets says that you get a list of messages from an API, something like:

  ```json
  {
    "messages": [
      /* etc */
    ],
    "nextPage": "<next-page-of-messages>"
  }
  ```

You can get the next page of messages, by sending the value for `nextPage` as a query parameter in a subsequent request.

By combining `LoadableState` and `PaginationFeature` from this library, we can write a feature like this:

```swift
struct Message: Identifiable {
  var id: String
}
@Reducer
struct MessagesFeature {
  struct State {
    // Wrap PaginationFeature state with LoadableState
    @LoadableStateWith<MessageRequest, PaginationFeature<Message>.State> var messages
  }
  enum Action {
    // The corresponding messages action
    case messages(
      // is a Loading Action
      LoadingAction<
        // generic over the kind of request sent to the `load` closure
        MessageRequest,
        // and the state/action types
        PaginationFeature<Message>.State,
        PaginationFeature<Message>.Action
      >
    )
  }
  @Dependency(\.api.loadMessages) var loadMessages
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // etc
      return .none
    }
    .loadable(\.$messages, action: \.messages) {
      PaginationFeature<Messages> { pageRequest in
        let response = try await loadMessages(cursor: pageRequest.cursor)
        return Page(
          next: response.nextPage,
          elements: response.messages
        )
      }
    } load: { request, state in
      let response = try await loadMessages()
      guard let firstMessage = response.messages.first else {
        fatalError("Handle no-results case")
      }
      return PaginationFeature.State(
        selection: firstMessage.id,
        next: response.nextPage,
        elements: response.messages
      )
    }
  }
}
```

In the above example, we _compose_ `PaginationFeature.State` inside the application feature. `PaginationFeature` is generic of the kind of object which is to be paginated, so `Message` in this example.

Because we need to also fetch the initial page of messages without any pagination cursors, we _wrap_ the `PaginationFeature<Message>.State` with `@LoadableState`. So this means that the `.messages` property itself is an optional, because initially it is in a `.pending` state.

### Initial Load

When the feature performs the initial `.load`, the closure calls the API, and constructs `PaginationFeature.State` from the response. In addition to the array of elements returned, the state value accepts `previous` and `next` pagination cursors. Here we define "next" to mean the values in the array which would be sorted after the current page of elements. If you API supports bi-directional pagination, the "previous" cursor is for those before the responses elements, however this value defaults to `nil`.

### Selection

The non-optional `selection` property can be used to track which element (across all pages) is currently selected. Because this is not and optional value, it might be necessary to consider how to handle the "empty result" edge case. A good idea would be to have a separate enum based feature for the `ResultsFeature` which includes a case for `.noResults`.

### Pagination Context

In some cases, it might be desirable to associate some additional metadata alongside your results. For example, perhaps the API also requires a "result-set-identifier", or it's necessary to keep hold of the total number of result elements. This is data which does not change or require mutation when performing pagination. In which case, create a specialised struct, which should conform to ``PaginationContext`` protocol, and set it as the `context` property.

## Pagination

To load another page or to change the selection, use the actions available via `PaginationFeature.Action`.

### Pagination Direction

The ``PaginationDirection`` enum has four cases, `.top`, `.bottom` for paging while vertically scrolling. And `.leading`, `.trailing` to enable "horizontal" paging, which will update the selection and also fetch a new page. The directions, `.top` and `.leading` both evaluate to showing or fetching elements which are before the current selection, while `.bottom` and `.trailing` show elements which are after the current selection. In other words, `.top` would prepend new elements to the list, and `.bottom` will append new elements.

### Load More

``PaginationLoadMore`` is a SwiftUI view which can be placed in a scroll view to support infinite scrolling. If using a SwiftUI List or a ScrollView, we would expect to place a `ForEach` view followed by a ``PaginationLoadMore`` view, to trigger loading of more elements.
