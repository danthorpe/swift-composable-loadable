#if compiler(<6.0) || !hasFeature(InferSendableFromCaptures)
#warning("Workaround for a bunch of Strict Concurrency related warnings. To be removed when Swift 6.0 is available.")
extension KeyPath: @unchecked Sendable {}
#endif
