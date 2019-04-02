package {
    import flash.system.Capabilities;

    public class Util {
        public static function getColorBetweenColors(color1:uint = 0xFFFFFF, color2:uint = 0x000000, percent:Number = 0.5):uint {
            if (percent < 0)
                percent = 0;
            if (percent > 1)
                percent = 1;

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

        public static function round(number:Number, decimals:int):Number {
            return int(number * Math.pow(10, decimals)) / Math.pow(10, decimals);
        }

        public static function getLengthOfObject(object:Object):Object {
            var count:int = 0;
            for (var s:String in object)
                count++;
            return count;
        }

        public static function isAir():Boolean {
            return Capabilities.playerType == "Desktop";
        }
    }
}
