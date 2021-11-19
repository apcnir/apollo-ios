import Foundation
import ApolloUtils

typealias TypeScope = Set<GraphQLCompositeType>

/// Defines the scope for an `IR.SelectionSet`. The scope is derived from the scope and all of its
/// parent scopes.
struct TypeScopeDescriptor: Equatable {
  let type: GraphQLCompositeType
  let fieldPath: ResponsePath
  let scope: TypeScope
  private let allTypes: CompilationResult.ReferencedTypes

  private init(
    type: GraphQLCompositeType,
    fieldPath: ResponsePath,
    scope: TypeScope,
    allTypes: CompilationResult.ReferencedTypes
  ) {
    self.type = type
    self.fieldPath = fieldPath
    self.scope = scope
    self.allTypes = allTypes
  }

  static func descriptor(
    forType type: GraphQLCompositeType,
    fieldPath: ResponsePath,
    givenAllTypes allTypes: CompilationResult.ReferencedTypes
  ) -> TypeScopeDescriptor {
    let scope = Self.typeScope(addingType: type, to: nil, givenAllTypes: allTypes)
    return TypeScopeDescriptor(type: type, fieldPath: fieldPath, scope: scope, allTypes: allTypes)
  }

  private static func typeScope(
    addingType newType: GraphQLCompositeType,
    to scope: TypeScope?,
    givenAllTypes allTypes: CompilationResult.ReferencedTypes
  ) -> TypeScope {
    if let scope = scope, scope.contains(newType) { return scope }

    var newScope = scope ?? []
    newScope.insert(newType)

    if let newType = newType as? GraphQLInterfaceImplementingType {
      newScope.formUnion(newType.interfaces)
      #warning("Do we need to recursively form union with each interfaces other interfaces? Test this.")
    }

    if let newType = newType as? GraphQLObjectType {
      newScope.formUnion(allTypes.unions(including: newType))
    }

    return newScope
  }

  func matches(_ otherScope: TypeScope) -> Bool {
    otherScope.isSubset(of: self.scope)
  }

  func matches(_ otherType: GraphQLCompositeType) -> Bool {
    self.scope.contains(otherType)
  }

  func appending(_ newType: GraphQLCompositeType) -> TypeScopeDescriptor {
    let scope = Self.typeScope(addingType: type, to: self.scope, givenAllTypes: self.allTypes)
    return TypeScopeDescriptor(
      type: type,
      fieldPath: fieldPath,
      scope: scope,
      allTypes: self.allTypes
    )
  }

  static func == (lhs: TypeScopeDescriptor, rhs: TypeScopeDescriptor) -> Bool {
    lhs.type == rhs.type &&
    lhs.fieldPath == rhs.fieldPath &&
    lhs.scope == rhs.scope
  }

}
