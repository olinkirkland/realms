package {
import flash.geom.Point;

import mx.core.UIComponent;
import mx.events.FlexEvent;

public class Map extends UIComponent {
    public static var NUM_POINTS:int = 50;

    public var points:Vector.<Point>;


    // Utility
    var i:int;

    public function Map() {
        addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
    }

    private function onCreationComplete(event:FlexEvent):void {
        pickPoints();
        drawPoints();

        var voronoi:Voronoi
    }

    public function pickPoints():void {
        // Pick points
        points = new Vector.<Point>;
        var r:Rand = new Rand(1);
        for (i = 0; i < NUM_POINTS; i++) {
            points.push(new Point(r.next() * width, r.next() * height));
        }
    }

    private function drawPoints():void {
        for (i = 0; i < points.length; i++) {
            graphics.beginFill(0xff0000);
            graphics.drawCircle(points[i].x, points[i].y, 3);
            graphics.endFill();
        }
    }
}
}
