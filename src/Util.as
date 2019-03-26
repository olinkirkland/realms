package {
    public class Util {
        public static function getColorBetweenColor(color1:uint = 0xFFFFFF, color2:uint = 0x000000, percent:Number = 0.5):uint {
            var r:uint = color1 >> 16;
            var g:uint = color1 >> 8 & 0xFF;
            var b:uint = color1 & 0xFF;

            r += ((color2 >> 16) - r) * percent;
            g += ((color2 >> 8 & 0xFF) - g) * percent;
            b += ((color2 & 0xFF) - b) * percent;

            return (r << 16 | g << 8 | b);
        }

        public static function randomColor():uint {
            return 0xffffff * Math.random();
        }

        public static function radiansToDegrees(value:Number):Number {
            return value * 180 / Math.PI
        }

        public static function degreesToRadians(value:Number):Number {
            return value * Math.PI / 180
        }

        public static function differenceBetweenTwoDegrees(degrees1:Number, degrees2:Number):Number {
            return 180 - Math.abs(Math.abs(degrees1 - degrees2) - 180);
        }

        public static function oppositeDegree(degree:Number):Number {
            return (degree + 180) % 360;
        }
    }
}
