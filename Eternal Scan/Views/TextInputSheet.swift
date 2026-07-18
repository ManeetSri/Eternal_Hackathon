//
//  TextInputSheet.swift
//  Eternal Scan — bottom sheet: AI meal-to-ingredients input.
//

import SwiftUI

struct TextInputSheet: View {
    @EnvironmentObject var vm: ShoppingViewModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ESColor.ai)
                    Text("AI Assistant")
                        .font(ESFont.sans(20, weight: .heavy))
                        .tracking(-0.8)
                        .textCase(.uppercase)
                }
                Spacer()
                Button { vm.sheet = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ESColor.foreground)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.black.opacity(0.05)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)

            // Textarea card
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if vm.query.isEmpty {
                        Text("pasta arrabbiata for 4")
                            .font(ESFont.sans(18, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.2))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $vm.query)
                        .font(ESFont.sans(18, weight: .bold))
                        .foregroundStyle(ESColor.foreground)
                        .scrollContentBackground(.hidden)
                        .frame(height: 96)
                        .focused($focused)
                }
                HStack {
                    Text("Free text · meal, servings, occasion").monoLabel(size: 10)
                    Spacer()
                    Text("\(vm.query.count)/140").monoLabel(size: 10)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(ESColor.border, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)

            // Suggestions
            VStack(alignment: .leading, spacing: 8) {
                Text("Try").monoLabel(size: 10)
                    .padding(.leading, 24)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.recipeSuggestions, id: \.self) { s in
                            Button { vm.query = s } label: {
                                Text(s)
                                    .font(ESFont.sans(12, weight: .medium))
                                    .foregroundStyle(ESColor.foreground)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(Color.white)
                                            .overlay(Capsule().stroke(ESColor.border, lineWidth: 1))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.top, 20)

            Spacer()

            Button(action: {
                vm.searchByIntentOrText()
                vm.sheet = nil
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(ESColor.ai)
                        .font(.system(size: 13, weight: .semibold))
                    Text("Generate Ingredients")
                        .font(ESFont.mono(11, weight: .heavy))
                        .kerning(2)
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(ESColor.foreground)
                        .opacity(vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.3 : 1)
                )
            }
            .disabled(vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear { focused = true }
    }
}

#Preview {
    TextInputSheet().environmentObject(ShoppingViewModel())
}
