{ pkgs }:
{
  system = {
    stateVersion = 4;
    defaults = {
      ActivityMonitor = {
        # CPU使用率をアプリアイコンに
        IconType = 5;
        # すべてのプロセス(階層表示)
        ShowCategory = 101;
      };
      alf = {
        # firewallを有効化
        globalstate = 1;
        # ファイアウォールへのリクエストのログ記録を有効化
        loggingenabled = 1;
        # ダウンロードされた署名付きソフトウェアが外部からの接続を受け入れるのを自動的に許可
        allowdownloadsignedenabled = 1;
      };
      controlcenter = {
        # AirDropの表示
        AirDrop = true;
        # バッテリーパーセントの表示
        BatteryShowPercentage = true;
        # Bluetoothの表示
        Bluetooth = true;
        # 再生中アイコンの表示
        NowPlaying = true;
      };
      # MacOSの自動アップデート
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      LaunchServices.LSQuarantine = false;
      NSGlobalDomain = {
        # メニューバーの自動非表示
        _HIHideMenuBar = true;
        # 拡張子を表示
        AppleShowAllExtensions = true;
        # 隠しファイルを表示
        AppleShowAllFiles = true;
        # ダークモード
        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = true;
        # スクロールバーでクリックした場所への即移動
        AppleScrollerPagingBehavior = true;
        # 切り替え先のアプリケーションのウィンドウが開いているワークスペースに移動する
        AppleSpacesSwitchOnActivate = false;
        # 新しいドキュメントを開くときにタブで開く
        AppleWindowTabbingMode = "always";
        # センチメートルを使用
        AppleMetricUnits = 1;
        AppleMeasurementUnits = "Centimeters";
        # 摂氏を使用
        AppleTemperatureUnit = "Celsius";
        # 行頭自動大文字化の有効化
        NSAutomaticCapitalizationEnabled = false;
        # スマートダッシュ機能(-- -> —)の有効化
        NSAutomaticDashSubstitutionEnabled = false;
        # スマートピリオド置換(... -> …)の有効化
        NSAutomaticPeriodSubstitutionEnabled = false;
        # スマート引用符機能(" -> “)の有効化
        NSAutomaticQuoteSubstitutionEnabled = false;
        # 自動スペル修正の有効化
        NSAutomaticSpellingCorrectionEnabled = false;
        # iCloudへの自動ドキュメント同期
        NSDocumentSaveNewDocumentsToCloud = false;
        # 拡張保存パネルの有効化
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        # 拡張プリントパネルの有効化
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        # ASCII制御文字の表示
        NSTextShowsControlCharacters = true;
        # フォーカスリングのアニメーションの有効化
        NSUseAnimatedFocusRing = false;
        # ウィンドウサイズ変更速度
        NSWindowResizeTime = 0.001;
        # ウィンドウ移動をControl+Commandで行うことができるようにする
        NSWindowShouldDragOnGesture = true;
        # スプリングローディングの有効化
        "com.apple.springing.enabled" = true;
        "com.apple.springing.delay" = 0.0;
        # 2本指でスワイプ
        AppleEnableSwipeNavigateWithScrolls = true;
      };
      WindowManager = {
        # stage managerの有効化
        GloballyEnabled = true;
        # Mission Control時に同一アプリをグループ化
        AppWindowGroupingBehavior = true;
        # 最近利用したアプリをstage manager上で非表示化
        AutoHide = true;
      };
      finder = {
        # 隠しファイルを表示
        AppleShowAllFiles = true;
        # 拡張子を表示
        AppleShowAllExtensions = true;
        # 拡張子の変更時に警告を出す
        FXEnableExtensionChangeWarning = false;
        # デフォルトのファイル一覧表示
        FXPreferredViewStyle = "clmv";
        # 30日でゴミ箱を空にする
        FXRemoveOldTrashItems = true;
        # finderの終了を許可する
        QuitMenuItem = true;
        # 外部ディスクをデスクトップに表示
        ShowExternalHardDrivesOnDesktop = true;
        # 接続されているサーバーをデスクトップに表示
        ShowMountedServersOnDesktop = true;
        # パスのパンくずリストを表示
        ShowPathbar = true;
        # 下部にディスク容量の表示
        ShowStatusBar = true;
        # POSIXファイルパスを表示
        _FXShowPosixPathInTitle = true;
        # 名前で並び変える時にフォルダを上に表示
        _FXSortFoldersFirst = true;
        _FXSortFoldersFirstOnDesktop = true;
      };
      dock = {
        # 自動非表示の有効化
        autohide = true;
        # 自動非表示の遅延
        autohide-delay = 0.1;
        # 非表示アニメーションの速度
        autohide-time-modifier = 0.5;
        # Mission Control アニメーションの速度
        expose-animation-duration = 0.5;
        show-recents = false;
        # Dockからアプリを開くアニメーションの無効化
        launchanim = false;
        # Dockのアニメーション
        mineffect = "scale";
        # Dockの表示位置
        orientation = "bottom";
        # スプリングローディングの有効化
        enable-spring-load-actions-on-all-items = true;
        # アプリスイッチャーを全画面に表示
        appswitcher-all-displays = true;
        persistent-apps = [
          {
            app = "/System/Applications/Launchpad.app/";
          }
          {
            app = "/Applications/Safari.app/";
          }
          {
            app = "/System/Applications/Mail.app/";
          }
          {
            app = "/System/Applications/Photos.app/";
          }
          {
            app = "/System/Applications/Calendar.app/";
          }
          {
            app = "/System/Applications/Reminders.app/";
          }
          {
            app = "/System/Applications/Notes.app/";
          }
          {
            app = "/System/Applications/App Store.app/";
          }
          {
            app = "/System/Applications/System Settings.app/";
          }
        ];
        # ホットコーナー設定(便利そうなものがあれば使いたい)
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };
      trackpad = {
        # サイレントクリックを有効化
        ActuationStrength = 1;
        # 軽いクリック
        FirstClickThreshold = 0;
        SecondClickThreshold = 0;
        # 副クリックの有効化
        TrackpadRightClick = true;
      };
      CustomUserPreferences."com.apple.AppleMultitouchTrackpad" = {

      };
      menuExtraClock = {
        # 24時間表示
        Show24Hour = true;
        # 完全な日付表示
        ShowDate = 1;
        # 月表示
        ShowDayOfMonth = true;
        # 曜日表示
        ShowDayOfWeek = true;
      };
    };
  };
}
