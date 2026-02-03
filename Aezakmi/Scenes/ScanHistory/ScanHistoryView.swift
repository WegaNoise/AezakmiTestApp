//
//  ScanHistoryView.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import SwiftUI

struct ScanHistoryView: View {
  @StateObject private var viewModel = ScanHistoryViewModel()
  @EnvironmentObject var mainVM: MainViewModel
  @State private var showingClearConfirmation = false
  @State private var showingFilterSheet = false
  @State private var selectedSession: ScanSession?
  @State private var showingSessionDetails = false
  
  var body: some View {
    ZStack {
      Color.mainBackground.ignoresSafeArea()
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 12) {
          Text("history_title".localized)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.textPrim)
          
          HStack {
            HStack(spacing: 16) {
              StatBadge(count: viewModel.totalSessions, label: "sessions_count".localized)
              StatBadge(count: viewModel.totalDevicesScanned, label: "devices_count".localized)
            }
            
            Spacer()
            Button {
              if let selected = viewModel.selectedDate {
                viewModel.datePickerDate = selected
              }
              showingFilterSheet = true
            } label: {
              Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title2)
                .foregroundColor(viewModel.hasActiveFilters ? .primary : .textTertia)
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        if !viewModel.scanSessions.isEmpty {
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor(.textTertia)
            TextField("search_devices".localized, text: $viewModel.searchText)
              .textFieldStyle(.plain)
            if !viewModel.searchText.isEmpty {
              Button {
                viewModel.searchText = ""
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.textTertia)
              }
            }
          }
          .padding(.horizontal, 12)
          .frame(height: 40)
          .background(Color.cardsBackground)
          .cornerRadius(10)
          .padding(.horizontal, 20)
          .padding(.bottom, 16)
        }
        if viewModel.hasActiveFilters {
          activeFiltersView
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        if viewModel.isLoading {
          loadingView
        } else if viewModel.filteredSessions.isEmpty {
          emptyStateView
        } else {
          sessionsListView
        }
        Spacer()
        if !viewModel.scanSessions.isEmpty {
          clearButtonView
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
      }
    }
    .navigationBarHidden(true)
    .sheet(isPresented: $showingFilterSheet) {
      filterSheetView
    }
    .confirmationDialog("clear_history_confirm".localized, isPresented: $showingClearConfirmation) {
      Button("clear_history".localized, role: .destructive) {
        viewModel.clearAllHistory()
      }
      Button("cancel".localized, role: .cancel) { }
    } message: {
      Text("action_cannot_be_undone".localized)
    }
    .alert("network_error".localized,
           isPresented: $viewModel.showAlert) {
      Button("ok".localized, role: .cancel) { }
    } message: {
      if let error = viewModel.errorMessage {
        Text(error)
      }
    }
  }
  
  private var activeFiltersView: some View {
    HStack {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          if let filter = viewModel.selectedFilter {
            FilterChip(
              label: filter.displayName,
              systemImage: filter.iconName,
              color: filter.color,
              onRemove: { viewModel.selectedFilter = nil }
            )
          }
          if let date = viewModel.selectedDate {
            FilterChip(
              label: formatDate(date),
              systemImage: "calendar",
              color: .accent,
              onRemove: { viewModel.selectedDate = nil }
            )
          }
          if !viewModel.searchText.isEmpty {
            FilterChip(
              label: "\("search".localized): \"\(viewModel.searchText)\"",
              systemImage: "magnifyingglass",
              color: .primary,
              onRemove: { viewModel.searchText = "" }
            )
          }
          Button("reset".localized) {
            viewModel.resetFilters()
          }
          .font(.caption)
          .foregroundColor(.primary)
          .padding(.horizontal, 8)
        }
      }
    }
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.locale = Locale.current
    return formatter.string(from: date)
  }
  
  private var loadingView: some View {
    VStack(spacing: 20) {
      Spacer()
      ProgressView()
        .scaleEffect(1.5)
      Text("loading".localized)
        .font(.body)
        .foregroundColor(.textSecond)
      Spacer()
    }
  }
  
  private var emptyStateView: some View {
    VStack(spacing: 24) {
      Spacer()
      Image(systemName: "clock.badge.questionmark")
        .font(.system(size: 80))
        .foregroundColor(.accent.opacity(0.3))
        .padding(.bottom, 8)
      VStack(spacing: 8) {
        Text(viewModel.hasActiveFilters ? "no_results".localized : "no_history".localized)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.textPrim)
        Text(viewModel.hasActiveFilters ? "no_results_message".localized : "no_history_message".localized)
        .font(.body)
        .foregroundColor(.textSecond)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
        if viewModel.hasActiveFilters {
          Button("reset".localized) {
            viewModel.resetFilters()
          }
          .font(.subheadline)
          .foregroundColor(.primary)
          .padding(.top, 8)
        }
      }
      Spacer()
    }
    .padding(.horizontal, 20)
  }
  
  private var sessionsListView: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(viewModel.filteredSessions) { session in
          NavigationLink {
            ScanSessionDetailView(session: session)
          } label: {
            ScanSessionRow(session: session)
              .padding(.horizontal, 20)
              .contextMenu {
                Button(role: .destructive) {
                  viewModel.deleteSession(session)
                } label: {
                  Label("delete".localized, systemImage: "trash")
                }
              }
          }
        }
      }
      .padding(.vertical, 16)
    }
  }
  
  private var clearButtonView: some View {
    Button(role: .destructive) {
      showingClearConfirmation = true
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "trash")
        Text("clear_history".localized)
      }
      .font(.subheadline)
      .foregroundColor(.statusError)
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .background(Color.statusError.opacity(0.1))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.statusError.opacity(0.3), lineWidth: 1)
      )
    }
  }
  
  private var filterSheetView: some View {
    NavigationView {
      List {
        Section("filters".localized) {
          ForEach(viewModel.filterOptions, id: \.self) { filter in
            Button {
              viewModel.selectedFilter = filter
              showingFilterSheet = false
            } label: {
              HStack {
                if let filter = filter {
                  Image(systemName: filter.iconName)
                    .foregroundColor(filter.color)
                  Text(filter.displayName)
                    .foregroundColor(.textPrim)
                } else {
                  Image(systemName: "square.grid.2x2")
                    .foregroundColor(.textTertia)
                  Text("all_types".localized)
                    .foregroundColor(.textPrim)
                }
                Spacer()
                if viewModel.selectedFilter == filter {
                  Image(systemName: "checkmark")
                    .foregroundColor(.primary)
                }
              }
            }
          }
        }
        
        Section("select_date".localized) {
          DatePicker("date".localized, selection: $viewModel.datePickerDate, displayedComponents: [.date])
            .datePickerStyle(.graphical)
            .onChange(of: viewModel.datePickerDate) { newValue in
              viewModel.selectedDate = newValue
            }
        }
      }
      .navigationTitle("filters".localized)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("done".localized) {
            showingFilterSheet = false
          }
        }
      }
    }
  }
}
