package {
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;

    import spark.primitives.Rect;

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

        public static function getDistanceBetweenTwoPoints(point1:Point, point2:Point):Number {
            return Math.sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y));
        }

        public static function isAir():Boolean {
            return Capabilities.playerType == "Desktop";
        }

        public static function getIntersect(p1:Point, p2:Point, p3:Point, p4:Point):Point {
            var v1:Point = new Point();
            var v2:Point = new Point();
            var d:Number;
            var intersectPoint:Point = new Point();

            v1.x = p2.x - p1.x;
            v1.y = p2.y - p1.y;
            v2.x = p4.x - p3.x;
            v2.y = p4.y - p3.y;

            d = v1.x * v2.y - v1.y * v2.x;
            if (!d) {
                // Points are collinear
                return null;
            }

            var a:Number = p3.x - p1.x;
            var b:Number = p3.y - p1.y;
            var t:Number = (a * v2.y - b * v2.x) / d;
            var s:Number = (b * v1.x - a * v1.y) / -d;
            if (t < 0 || t > 1 || s < 0 || s > 1) {
                // Line segments don't intersect
                return null;
            }

            intersectPoint.x = p1.x + v1.x * t;
            intersectPoint.y = p1.y + v1.y * t;
            return intersectPoint;
        }

        public static function removeDuplicatesFromArray(arr:Array):Array {
            var uniqueArr:Array = [];
            for each (var value:* in arr) {
                if (uniqueArr.indexOf(value) < 0)
                    uniqueArr.push(value);
            }

            return uniqueArr;
        }

        public static function capitalizeFirstLetter(str:String):String {
            return str.substr(0, 1).toUpperCase() + str.substr(1);
        }

        public static function randomElementFromArray(arr:Array, r:Rand):Object {
            var i:int = r.between(0, arr.length);
            return arr[i];
        }


        public static function keysFromObject(obj:Object):Array {
            var arr:Array = [];
            for (var key:String in obj) {
                arr.push(key);
            }
            return arr;
        }

        public static function generateNoisyPoints(p1:Point,
                                                   p2:Point,
                                                   iterations:int):Array {
            var rand:Rand = new Rand(int(p1.x * p1.y));

            var arr:Array = [p1,
                p2];

            for (var i:int = 0; i < iterations; i++) {
                var newArray:Array = [arr[0]];

                var change:Number = 1.5;
                var mod:Number = i + 1;

                for (var j:int = 0; j < arr.length - 1; j++) {
                    var p:Point = pointBetweenPoints(arr[j],
                            arr[j + 1]);

                    p.x += rand.between(-change / mod,
                            change / mod);
                    p.y += rand.between(-change / mod,
                            change / mod);

                    newArray.push(p,
                            arr[j + 1]);
                }

                arr = newArray;
            }

            return arr;
        }

        public static function pointBetweenPoints(p1:Point,
                                                  p2:Point):Point {
            return new Point((p1.x + p2.x) / 2,
                    (p1.y + p2.y) / 2);
        }

        public static function sharedPropertiesBetweenArrays(arr1:Array, arr2:Array):Array {
            var shared:Array = [];
            for each (var element:* in arr1)
                if (arr2.indexOf(element) > -1)
                    shared.push(element);
            return shared;
        }

        public static function getAngleBetweenTwoPoints(point1:Point, point2:Point):Number {
            var perpendicular:Number = (point1.y - point2.y);
            var base:Number = (point1.x - point2.x);
            return radiansToDegrees(Math.atan2(perpendicular, base));
        }

        public static function getCompassDirectionFromDegrees(degrees:int):String {
            if (degrees > 315 || degrees < 45)
                return "north";
            if (degrees < 135)
                return "east"
            if (degrees < 225)
                return "south";
            if (degrees < 315)
                return "west"

            // Unknown degrees
            return "[" + degrees + "]";
        }

        public static function oppositeCompassDirection(compassDirection:String):String {
            var directions:Object = {north: "south", east: "west", south: "north", west: "east"};
            if (directions.hasOwnProperty(compassDirection))
                return directions[compassDirection];
            else
                return "[" + compassDirection + "]";
        }

        public static function getBoundsFromPoints(points:Array):Rectangle {
            // Sort
            var topLeft:Point = new Point(points[0].x, points[0].y);
            var bottomRight:Point = new Point(points[0].x, points[0].y);

            for each (var point:Point in points) {
                if (point.x < topLeft.x)
                    topLeft.x = point.x;
                if (point.y < topLeft.y)
                    topLeft.y = point.y;
                if (point.x > bottomRight.x)
                    bottomRight.x = point.x;
                if (point.y > bottomRight.y)
                    bottomRight.y = point.y;
            }

            return new Rectangle(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
        }
    }
}
