pragma Singleton
import QtQuick

QtObject {
  // Couleurs principales — Berry Blush nuit + Almond Silk
  readonly property color bg:     "#14101D"
  readonly property color bg2:    "#241B38"
  readonly property color bg3:    "#322547"
  readonly property color fg:     "#D8CDF5"
  readonly property color fgd:    Qt.rgba(216/255, 205/255, 245/255, 0.5)
  readonly property color fgdd:   Qt.rgba(216/255, 205/255, 245/255, 0.2)

  // Accents — palete rose
  readonly property color a1:     "#A78BFA"
  readonly property color a2:     "#A78BFA"
  readonly property color a3:     "#D8CDF5"
  readonly property color a4:     "#A78BFA"

  // Bordures
  readonly property color ln:     Qt.rgba(216/255, 205/255, 245/255, 0.12)
  readonly property color lnm:    Qt.rgba(216/255, 205/255, 245/255, 0.22)

  // Font
  readonly property string mono:  "SF Mono"

  // Timings animations
  readonly property int durationFast:   150
  readonly property int durationMid:    380
  readonly property int durationSlow:   650
}