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
    }
}
