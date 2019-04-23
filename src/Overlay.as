package {
    import assets.icons.Icons;

    import flash.display.MovieClip;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import generation.City;
    import generation.Civilization;
    import generation.Geography;
    import generation.towns.Town;

    import labels.IconLabel;
    import labels.LandLabel;
    import labels.MapLabel;
    import labels.RegionLabel;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    public class Overlay extends UIComponent {
        public var map:Map;
        public var regionLabelsLayer:MovieClip;
        public var citiesAndTownsLayer:MovieClip;

        private var geo:Geography;
        private var civ:Civilization;

        public function Overlay() {
            geo = Geography.getInstance();
            civ = Civilization.getInstance();

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            regionLabelsLayer = new MovieClip();
            addChild(regionLabelsLayer);
            citiesAndTownsLayer = new MovieClip();
            addChild(citiesAndTownsLayer);
        }

        public function validate():void {
            x = map.x;
            y = map.y;
        }

        public function drawLabels():void {
            // Clear old labels
            regionLabelsLayer.graphics.clear();
            while (regionLabelsLayer.numChildren > 0)
                regionLabelsLayer.removeChildAt(0);

            // Clear old icons
            citiesAndTownsLayer.graphics.clear();
            while (citiesAndTownsLayer.numChildren > 0)
                citiesAndTownsLayer.removeChildAt(0);

            // Draw new labels
            //labelLands();
            labelRegions();
            labelCitiesAndTowns();

            // Position labels
            positionLabels(1);
        }

        public function positionLabels(scale:Number):void {
            // Position labels
            positionLayerChildren(scale, regionLabelsLayer);
            positionLayerChildren(scale, citiesAndTownsLayer);

            handleLabelIntersections();
        }

        public function positionLayerChildren(scale:Number, layer:MovieClip):void {
            for (var i:int = 0; i < layer.numChildren; i++) {
                var label:MapLabel = layer.getChildAt(i) as MapLabel;
                label.x = label.point.x * scale;
                label.y = label.point.y * scale;
            }
        }

        private function handleLabelIntersections():void {
            // Make sure labels aren't overlapping
            var intersections:int;
            do {
                intersections = 0;
                for (var i:int = 0; i < regionLabelsLayer.numChildren; i++) {
                    for (var j:int = 0; j < regionLabelsLayer.numChildren; j++) {
                        if (i != j) {
                            var label1:MapLabel = regionLabelsLayer.getChildAt(i) as MapLabel;
                            var label2:MapLabel = regionLabelsLayer.getChildAt(j) as MapLabel;
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
                regionLabelsLayer.addChild(label);
            }
        }

        private function labelRegions():void {
            var regionLabels:Array = [];
            for each (var region:Object in civ.regions) {
                var label:RegionLabel = new RegionLabel(region);
                label.point = new Point(region.centroid.x, region.centroid.y);
                regionLabels.push(label);
            }

            regionLabels.sort(function (n1:Object, n2:Object):Number {
                if (n1.point.x > n2.point.x)
                    return 1;
                else if (n1.point.x < n2.point.x)
                    return -1;
                else
                    return 0;
            });

            for each (label in regionLabels)
                regionLabelsLayer.addChild(label);
        }

        private function labelCitiesAndTowns():void {
            var label:IconLabel;
            for each (var city:City in civ.cities) {
                label = new IconLabel(new Icons.City());
                label.point = new Point(city.cell.point.x, city.cell.point.y);
                label.x = label.point.x;
                label.y = label.point.y;
                citiesAndTownsLayer.addChild(label);
            }
            for each (var town:Town in civ.towns) {
                label = new IconLabel(Icons.townIconFromType(town.townType));
                label.point = new Point(town.cell.point.x, town.cell.point.y);
                label.x = label.point.x;
                label.y = label.point.y;
                citiesAndTownsLayer.addChild(label);
            }
        }

        public function toggle():void {
            for (var i:int = 0; i < numChildren; i++)
                getChildAt(i).visible = !getChildAt(i).visible;
        }
    }
}