/*
*/

import Foundation

public struct TrekkingfyProducts {
  
  public static let TrekkingfyFullApp = "com.riccardorizzo.trekkingfy.fullapp"
  //public static let TrekkingfyFullApp = "com.riccardorizzo.trekkingfy.consumable"
    
  fileprivate static let productIdentifiers: Set<ProductIdentifier> = [TrekkingfyProducts.TrekkingfyFullApp]

  public static let store = IAPHelper(productIds: TrekkingfyProducts.productIdentifiers)
    
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
  return productIdentifier.components(separatedBy: ".").last
}
