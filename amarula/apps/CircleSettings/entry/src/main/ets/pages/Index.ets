interface SettingTile {
  id: string;
  label: string;
  subtitle: string;
}

@Entry
@Component
struct Index {
  @State tiles: SettingTile[] = [
    { id: 'privacy',    label: 'Privacy',       subtitle: 'You are not the product' },
    { id: 'modes',      label: 'Modes',         subtitle: 'Personality & age modes' },
    { id: 'network',    label: 'Network',       subtitle: 'Firewall, lobby, mesh' },
    { id: 'threats',    label: 'Community Defense', subtitle: 'Threat intel & reports' },
    { id: 'apps',       label: 'Apps',          subtitle: 'Permissions & toggles' },
    { id: 'ota',        label: 'System Update', subtitle: 'Over-the-air & mesh' },
    { id: 'storage',    label: 'Storage',       subtitle: 'Device & mesh sync' },
    { id: 'a11y',       label: 'Accessibility', subtitle: 'Elder mode, reduced motion' },
    { id: 'about',      label: 'About',         subtitle: 'Amarula · v0.0.1' }
  ];

  build() {
    Column() {
      Text('Welcome to the Circle')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 8, left: 20, right: 20 })

      Text("You're NOT the product. Trust!")
        .fontSize(14)
        .opacity(0.7)
        .margin({ bottom: 24, left: 20, right: 20 })

      List({ space: 12 }) {
        ForEach(this.tiles, (tile: SettingTile) => {
          ListItem() {
            Row() {
              Column() {
                Text(tile.label).fontSize(17).fontWeight(FontWeight.Medium)
                Text(tile.subtitle).fontSize(13).opacity(0.6).margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('>').fontSize(20).opacity(0.4)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFF5F0EB')
            .borderRadius(12)
            .onClick(() => {
              console.info(`tile tapped: ${tile.id}`);
            })
          }
        })
      }
      .layoutWeight(1)
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFBF7')
  }
}
