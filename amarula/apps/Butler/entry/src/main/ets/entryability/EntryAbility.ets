import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';

const DOMAIN = 0x0000;
const TAG = 'Butler';

export default class EntryAbility extends UIAbility {
  onCreate(): void { hilog.info(DOMAIN, TAG, 'onCreate'); }
  onDestroy(): void { hilog.info(DOMAIN, TAG, 'onDestroy'); }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
    });
  }

  onForeground(): void { hilog.info(DOMAIN, TAG, 'onForeground'); }
  onBackground(): void { hilog.info(DOMAIN, TAG, 'onBackground'); }
}
