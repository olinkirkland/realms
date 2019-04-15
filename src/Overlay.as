package {
    import flash.display.MovieClip;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import generation.Civilization;
    import generation.Geography;

    import labels.LandLabel;
    import labels.MapLabel;
    import labels.RegionLabel;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

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
            labelRegions();

            // Position labels
            positionLabels(1);
        }

        public function positionLabels(scale:Number):void {
            // Position labels
            for (var i:int = 0; i < overlay.numChildren; i++) {
                var label:MapLabel = overlay.getChildAt(i) as MapLabel;
                label.x = label.point.x * scale;
                label.y = label.point.y * scale;
            }

            // Make sure labels aren't overlapping
            var intersections:int;
            do {
                intersections = 0;
                for (i = 0; i < overlay.numChildren; i++) {
                    for (var j:int = 0; j < overlay.numChildren; j++) {
                        if (i != j) {
                            var label1:MapLabel = overlay.getChildAt(i) as MapLabel;
                            var label2:MapLabel = overlay.getChildAt(j) as MapLabel;
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
            } while (intersections > 0);
        }

        private function labelLands():void {
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                var label:LandLabel = new LandLabel(land);
                label.point = new Point(land.centroid.x, land.centroid.y);
                overlay.addChild(label);
            }
        }

        private function labelRegions():void {
            for each (var region:Object in civ.regions) {
                var label:RegionLabel = new RegionLabel(region);
                label.point = new Point(region.centroid.x, region.centroid.y);
                overlay.addChild(label);
            }
        }
    }
}