package {
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Point;

    public class AirOnlyUtil {
        public static function loadPointsFromFile():Vector.<Point> {
            var points:Vector.<Point>;
            var pointsFile:File = File.applicationStorageDirectory.resolvePath("points.json");
            if (pointsFile.exists) {
                // Load the points file
                trace("Points file found; Loading points from file");
                var stream:FileStream = new FileStream();

                stream.open(pointsFile, FileMode.READ);
                var pointsData:Object = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
                stream.close();

                points = new Vector.<Point>();
                for each (var pointData:Object in pointsData) {
                    points.push(new Point(pointData.x, pointData.y));
                }
                if (points.length != Map.NUM_POINTS) {
                    trace("Points file incompatible or corrupted, deleting points file");
                    pointsFile.deleteFile();
                }
            }

            return points;
        }

        public static function savePointsToFile(points:Vector.<Point>):void {
            var pointsFile:File = File.applicationStorageDirectory.resolvePath("points.json");
            var stream:FileStream = new FileStream();
            stream.open(pointsFile, FileMode.WRITE);
            stream.writeUTFBytes(JSON.stringify(points));
            stream.close();
            trace("Points saved to " + pointsFile.url);
        }
    }
}