# ``ComposableLoadable``

A micro-library to provide a "loading" capability to projects built with [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) (TCA).

## Overview

Often applications need to load data from some external system so that the user may proceed. The most proto-typical example of this is loading some data from the network which is then displayed to the user.

The external system might could also be file storage or some other process, to the extent that we will just model it as `(Request) async throws -> Output`.

While this is a very general scenario, this library is highly opinionated and is only to be used in applications which are built using TCA. As such, it assumes that a parent feature _loads_ data which is required to create the child state. Therefore the loading function is actually `(Request) async throws -> ChildFeature.State`.

## Topics

### State

- ``LoadableState``

### Action

- ``LoadingAction``

### Reducer

- ``ComposableArchitecture/Reducer/loadable(_:action:child:load:fileID:line:)-83g09``

- ``ComposableArchitecture/Reducer/loadable(_:action:child:load:fileID:line:)-5hsv5``
