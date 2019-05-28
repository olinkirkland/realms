package {
    import flash.events.Event;

    import graph.Cell;

    public class MapClickEvent extends Event {
        public var cell:Cell;

        public function MapClickEvent(cell:Cell) {
            super(Map.CLICK_EVENT, true);

            this.cell = cell;
        }
    }
}
