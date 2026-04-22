import { CircleColor, CircleType, CircleSpace, CirclePhrases } from '@circle/design';

interface Turn {
  role: 'user' | 'butler';
  text: string;
}

@Entry
@Component
struct Index {
  @State transcript: Turn[] = [
    { role: 'butler', text: "Sawubona. I'm B!. Tap the mic to talk, or type below." }
  ];
  @State input: string = '';
  @State listening: boolean = false;

  private appendTurn(turn: Turn) {
    this.transcript = [...this.transcript, turn];
  }

  private send() {
    if (!this.input.trim()) return;
    this.appendTurn({ role: 'user', text: this.input });
    const echo = this.input;
    this.input = '';
    // Placeholder — real inference lands when CircleInference service ports from AOSP.
    setTimeout(() => {
      this.appendTurn({ role: 'butler', text: `(stub) I heard: "${echo}"` });
    }, 300);
  }

  private toggleMic() {
    this.listening = !this.listening;
    // Real ASR (Sherpa-ONNX) wires in later.
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('B!').fontSize(CircleType.Title).fontWeight(FontWeight.Bold).fontColor(CircleColor.Deep)
        Blank()
        Text(CirclePhrases.Tagline).fontSize(CircleType.Caption).opacity(0.5)
      }
      .width('100%')
      .padding(CircleSpace.L)

      // Transcript
      List({ space: CircleSpace.S }) {
        ForEach(this.transcript, (turn: Turn, idx: number) => {
          ListItem() {
            Row() {
              if (turn.role === 'butler') {
                Text(turn.text)
                  .fontSize(CircleType.Body)
                  .fontColor(CircleColor.TextPrimary)
                  .padding(CircleSpace.M)
                  .backgroundColor(CircleColor.BgElevated)
                  .borderRadius(CircleRadius.Medium)
              } else {
                Blank()
                Text(turn.text)
                  .fontSize(CircleType.Body)
                  .fontColor(CircleColor.TextOnDark)
                  .padding(CircleSpace.M)
                  .backgroundColor(CircleColor.Deep)
                  .borderRadius(CircleRadius.Medium)
              }
            }.width('100%')
          }
        }, (turn: Turn, idx: number) => `${idx}`)
      }
      .layoutWeight(1)
      .padding({ left: CircleSpace.L, right: CircleSpace.L })

      // Input bar
      Row({ space: CircleSpace.S }) {
        TextInput({ placeholder: 'Ask B! anything', text: this.input })
          .layoutWeight(1)
          .onChange((v: string) => { this.input = v; })
          .onSubmit(() => this.send())

        Button(this.listening ? '●' : '🎤')
          .backgroundColor(this.listening ? CircleColor.BlockedRed : CircleColor.Gold)
          .fontColor(CircleColor.TextOnDark)
          .onClick(() => this.toggleMic())
      }
      .width('100%')
      .padding(CircleSpace.M)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CircleColor.BgPrimary)
  }
}

// Radius import (tiny alias to avoid adding another top-of-file import line)
class CircleRadius {
  static readonly Medium: number = 12;
}
