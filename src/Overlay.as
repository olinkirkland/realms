package {
    import flash.display.MovieClip;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import generation.Civilization;
    import generation.Geography;

    import labels.LandLabel;

    import labels.RegionLabel;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    import spark.primitives.Rect;

    public class Overlay extends UIComponent {
        public var map:Map;
        public var overlay:MovieClip;

        private var geo:Geography;
        private var civ:Civilization;

        public function Overlay() {
            geo = Geography.getInstance();
            civ = Civilization.getInstance();

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            overlay = new MovieClip();
            addChild(overlay);
        }

        public function validate():void {
            x = map.x;
            y = map.y;
        }

        public function drawLabels():void {
            // Clear old labels
            overlay.graphics.clear();
            while (overlay.numChildren > 0)
                overlay.removeChildAt(0);

            // Draw new labels
            labelLands();
//            labelRegions();

            // Space out labels
            spaceLabels();
        }

        private function spaceLabels():void {
            // Make sure labels aren't overlapping
            var intersections:int;
            do {
                intersections = 0;
                for (var i:int = 0; i < overlay.numChildren; i++) {
                    for (var j:int = 0; j < overlay.numChildren; j++) {
                        if (i != j) {
                            var label1:Object = overlay.getChildAt(i);
                            var label2:Object = overlay.getChildAt(j);
                            if (label1.getBounds(this).intersects(label2.getBounds(this))) {
                                while (label1.getBounds(this).intersects(label2.getBounds(this))) {
                                    var rect:Rectangle = label1.getBounds(this).intersection(label2.getBounds(this));
                                    if (rect.width < rect.height) {
                                        if (label1.x > label2.x) {
                                            label1.x++;
                                            label2.x--;
                                        } else {
                                            label1.x--;
                                            label2.x++;
                                        }
                                    } else {
                                        if (label1.y > label2.y) {
                                            label1.y++;
                                            label2.y--;
                                        } else {
                                            label1.y--;
                                            label2.y++;
                                        }
                                    }
                                }
                                intersections++;
                            }
                        }
                    }
                }
            } while (intersections > 0)
        }

        private function labelLands():void {
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                var point:Point = land.centroid;
                var label:LandLabel = new LandLabel(land);
                overlay.addChild(label);
                label.x = point.x;
                label.y = point.y;
            }
        }

        private function labelRegions():void {
            for each (var region:Object in civ.regions) {
                var point:Point = region.centroid;
                var label:RegionLabel = new RegionLabel(region);
                overlay.addChild(label);
                label.x = point.x;
                label.y = point.y;
            }
        }
    }
}