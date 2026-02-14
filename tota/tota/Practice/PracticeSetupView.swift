import LiveKitComponents
import SwiftUI

struct PracticeSetupView: View {
    @Bindable var viewModel: PracticeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header()
                languagePicker()
                scenarioList()
                voicePicker()
                startButton()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Header

    private func header() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("practice")
                .font(.largeTitle.weight(.bold))
            Text("pick a language, scenario, and voice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Language Picker

    private func languagePicker() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("language")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PracticeData.languages) { language in
                        languageChip(language)
                    }
                }
            }
        }
    }

    private func languageChip(_ language: Language) -> some View {
        let isSelected = viewModel.selectedLanguage == language
        return Button {
            viewModel.selectedLanguage = language
        } label: {
            VStack(spacing: 2) {
                Text(language.nativeName)
                    .font(.title3.weight(.semibold))
                Text(language.name)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.brand : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Scenario List

    private func scenarioList() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("scenario")
                .font(.headline)

            LazyVStack(spacing: 8) {
                ForEach(PracticeData.scenarios) { scenario in
                    scenarioCard(scenario)
                }
            }
        }
    }

    private func scenarioCard(_ scenario: Scenario) -> some View {
        let isSelected = viewModel.selectedScenario == scenario
        return Button {
            viewModel.selectedScenario = scenario
        } label: {
            HStack(spacing: 14) {
                Image(systemName: scenario.icon)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(isSelected ? Theme.brand : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.name)
                        .font(.body.weight(.medium))
                    Text(scenario.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Theme.brand : .clear, lineWidth: 2)
            )
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Voice Picker

    private func voicePicker() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("voice")
                .font(.headline)

            Picker("voice", selection: $viewModel.selectedVoice) {
                ForEach(PracticeData.voices) { voice in
                    Text(voice.name)
                        .tag(voice)
                }
            }
        }
    }

    // MARK: - Start Button

    private func startButton() -> some View {
        AsyncButton {
            await viewModel.startSession()
        } label: {
            Text("start practicing")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        } busyLabel: {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.brand)
        .padding(.top, 8)
    }
}
