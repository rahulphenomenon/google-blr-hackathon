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
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private func header() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Practice")
                .font(.largeTitle.weight(.bold))
            Text("Pick a language, scenario, and voice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Language Picker

    private func languagePicker() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Language")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(PracticeData.languages) { language in
                        languageChip(language)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func languageChip(_ language: Language) -> some View {
        let isSelected = viewModel.selectedLanguage == language
        return Button {
            viewModel.selectedLanguage = language
        } label: {
            VStack(spacing: 4) {
                Text(language.nativeName)
                    .font(.title3.weight(.semibold))
                Text(language.name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color(.label) : Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Scenario List

    private func scenarioList() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scenario")
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
                    .foregroundStyle(isSelected ? .white : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.name)
                        .font(.body.weight(.medium))
                    Text(scenario.description)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
            }
            .padding(14)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color(.label) : Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Voice Picker

    private func voicePicker() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(PracticeData.voices) { voice in
                        voiceCard(voice)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func voiceCard(_ voice: Voice) -> some View {
        let isSelected = viewModel.selectedVoice == voice
        return Button {
            viewModel.selectedVoice = voice
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(voice.name)
                    .font(.subheadline.weight(.semibold))
                Text(voice.personality)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(width: 150, alignment: .leading)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color(.label) : Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Start Button

    private func startButton() -> some View {
        AsyncButton {
            await viewModel.startSession()
        } label: {
            Text("Start Practicing")
                .font(.headline)
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        } busyLabel: {
            ProgressView()
                .tint(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(.label))
        .clipShape(.rect(cornerRadius: 14))
        .padding(.top, 8)
    }
}
