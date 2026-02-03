//
//  ScanSubViews.swift
//  Aezakmi
//
//  Created by petar on 06.02.2026.
//
import SwiftUI

struct StatBadge: View {
  let count: Int
  let label: String
  var body: some View {
    VStack(spacing: 2) {
      Text("\(count)")
        .font(.headline)
        .foregroundColor(.primary)
      Text(label)
        .font(.caption2)
        .foregroundColor(.textSecond)
    }
  }
}

struct FilterChip: View {
  let label: String
  let systemImage: String
  let color: Color
  let onRemove: () -> Void
  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: systemImage)
        .font(.caption2)
        .foregroundColor(color)
      Text(label)
        .font(.caption)
        .foregroundColor(.textPrim)
      Button {
        onRemove()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.caption2)
          .foregroundColor(.textTertia)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(color.opacity(0.1))
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(color.opacity(0.3), lineWidth: 1)
    )
  }
}

struct DeviceStatBadge: View {
  let count: Int
  let type: DeviceType
  
  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: type.iconName)
        .font(.caption2)
        .foregroundColor(type.color)
      Text("\(count)")
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.textPrim)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(type.color.opacity(0.1))
    .cornerRadius(6)
  }
}

struct DevicePreviewBadge: View {
  let name: String
  let type: DeviceType
  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: type.iconName)
        .font(.caption2)
        .foregroundColor(type.color)
      Text(name)
        .font(.caption2)
        .foregroundColor(.textPrim)
        .lineLimit(1)
        .frame(maxWidth: 100)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(type.color.opacity(0.05))
    .cornerRadius(6)
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(type.color.opacity(0.2), lineWidth: 1)
    )
  }
}
