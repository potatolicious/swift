//===--- LibPrespecialized.h - Interface for prespecializations -*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// Interface for interacting with prespecialized metadata library.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_LIB_PRESPECIALIZED_H
#define SWIFT_LIB_PRESPECIALIZED_H

#include "PrebuiltStringMap.h"
#include "swift/ABI/Metadata.h"
#include "swift/ABI/TargetLayout.h"

#define LIB_PRESPECIALIZED_TOP_LEVEL_SYMBOL_NAME "_swift_prespecializationsData"

namespace swift {

template <typename Runtime>
struct LibPrespecializedData {
  uint32_t majorVersion;
  uint32_t minorVersion;

  TargetPointer<Runtime, const void> metadataMap;

  static constexpr uint32_t currentMajorVersion = 1;
  static constexpr uint32_t currentMinorVersion = 1;

  // Helpers for retrieving the metadata map in-process.
  static bool stringIsNull(const char *str) { return str == nullptr; }

  using MetadataMap = PrebuiltStringMap<const char *, Metadata *, stringIsNull>;

  const MetadataMap *getMetadataMap() const {
    return reinterpret_cast<const MetadataMap *>(metadataMap);
  }
};

const LibPrespecializedData<InProcess> *getLibPrespecializedData();
Metadata *getLibPrespecializedMetadata(const TypeContextDescriptor *description,
                                       const void *const *arguments);

} // namespace swift

#endif // SWIFT_LIB_PRESPECIALIZED_H
