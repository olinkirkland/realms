package {

    import fl.motion.BezierSegment;

    import flash.geom.Point;


    public class CubicBezier {
        public static function curveThroughPoints(points:Array):Array {
            var p:Point = points[0];
            points.unshift(p);
            p = points[points.length - 1];
            points.push(p);


            // Options
            var z:Number = .5;
            var angleFactor:Number = .75;

            //
            // First calculate all the curve control points
            //

            // There must be more than 2 points
            if (points.length <= 2) {
                return points;
            }

            // Ordinarily, curve calculations will start with the second point and go through the second-to-last point
            var firstPointIndex:int = 1;
            var lastPointIndex:int = points.length - 1;

            var controlPoints:Array = new Array();
            for (var i:int = firstPointIndex; i < lastPointIndex; i++) {
                var p0:Point = (i - 1 < 0) ? points[points.length - 2] : points[i - 1];
                var p1:Point = points[i];
                var p2:Point = (i + 1 == points.length) ? points[1] : points[i + 1];
                var a:Number = Point.distance(p0,
                        p1);
                if (a < 0.001) {
                    a = .001;
                }

                var b:Number = Point.distance(p1,
                        p2);
                if (b < 0.001) {
                    b = .001;
                }
                var c:Number = Point.distance(p0,
                        p2);
                if (c < 0.001) {
                    c = .001;
                }
                var cos:Number = (b * b + a * a - c * c) / (2 * b * a);
                if (cos < -1) {
                    cos = -1;
                } else if (cos > 1) {
                    cos = 1;
                }
                var C:Number = Math.acos(cos);

                var aPt:Point = new Point(p0.x - p1.x,
                        p0.y - p1.y);
                var bPt:Point = new Point(p1.x,
                        p1.y);
                var cPt:Point = new Point(p2.x - p1.x,
                        p2.y - p1.y);

                if (a > b) {
                    aPt.normalize(b);
                } else if (b > a) {
                    cPt.normalize(a);
                }

                aPt.offset(p1.x,
                        p1.y);
                cPt.offset(p1.x,
                        p1.y);

                var ax:Number = bPt.x - aPt.x;
                var ay:Number = bPt.y - aPt.y;
                var bx:Number = bPt.x - cPt.x;
                var by:Number = bPt.y - cPt.y;
                var rx:Number = ax + bx;
                var ry:Number = ay + by;
                if (rx == 0 && ry == 0) {
                    rx = -bx;
                    ry = by;
                }
                if (ay == 0 && by == 0) {
                    rx = 0;
                    ry = 1;
                } else if (ax == 0 && bx == 0) {
                    rx = 1;
                    ry = 0;
                }
                var r:Number = Math.sqrt(rx * rx + ry * ry);
                var theta:Number = Math.atan2(ry,
                        rx);

                var controlDist:Number = Math.min(a,
                        b) * z;
                var controlScaleFactor:Number = C / Math.PI;
                controlDist *= ((1 - angleFactor) + angleFactor * controlScaleFactor);
                var controlAngle:Number = theta + Math.PI / 2;
                var controlPoint2:Point = Point.polar(controlDist,
                        controlAngle);
                var controlPoint1:Point = Point.polar(controlDist,
                        controlAngle + Math.PI);
                controlPoint1.offset(p1.x,
                        p1.y);
                controlPoint2.offset(p1.x,
                        p1.y);
                if (Point.distance(controlPoint2,
                        p2) > Point.distance(controlPoint1,
                        p2)) {
                    controlPoints[i] = [controlPoint2,
                        controlPoint1];
                } else {
                    controlPoints[i] = [controlPoint1,
                        controlPoint2];
                }
            }

            //
            // Get the points on the curve and return them
            //

            var curve:Array = [];
            for (i = firstPointIndex; i < lastPointIndex - 1; i++) {
                var bezier:BezierSegment = new BezierSegment(points[i],
                        controlPoints[i][1],
                        controlPoints[i + 1][0],
                        points[i + 1]);

                for (var t:Number = .01; t < 1; t += .2) {
                    p = bezier.getValue(t);
                    p = bezier.getValue(t + .01);
                    curve.push(p);
                }
            }

            if (lastPointIndex == points.length - 1) {
                curve.push(points[i + 1]);
            }

            // Remove duplicates
            var noDuplicatesCurve:Array = [];
            var duplicate:Boolean;
            for (i = 0; i < curve.length; i++) {
                duplicate = false;
                for (var j:int = 0; j < noDuplicatesCurve.length; j++) {
                    if (noDuplicatesCurve[j].equals(curve[i])) {
                        duplicate = true;
                    }
                }
                if (!duplicate) {
                    noDuplicatesCurve.push(curve[i]);
                }
            }


            return noDuplicatesCurve;
        }
    }
}