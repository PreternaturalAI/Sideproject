//
// Copyright (c) Vatsal Manot
//

import Swift

/// Some useful numbers when working with `text-embedding-ada-002`.
///
/// From https://github.com/MSUSAzureAccelerators/Knowledge-Mining-with-OpenAI.
///
/// Don't rely on these numbers to improve the quality of your retrieval pipeline, always perform your own experimentation.
public enum MSFT_KnowledgeMiningWithOpenAI {
    public static let SMALL_EMB_TOKEN_NUM  = 125
    public static let MEDIUM_EMB_TOKEN_NUM  = 250
    public static let LARGE_EMB_TOKEN_NUM  = 500
    public static let X_LARGE_EMB_TOKEN_NUM = 800
}
