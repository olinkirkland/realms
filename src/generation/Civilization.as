package generation {
    import graph.Cell;

    import mx.utils.UIDUtil;

    public class Civilization {
        private static var _instance:Civilization;

        // Generation
        public var settlementsById:Object = {};
        public var settlementsByCell:Object = {};
        public var regions:Object = {};

        public function Civilization() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;
        }

        public static function getInstance():Civilization {
            if (!_instance)
                new Civilization();
            return _instance;
        }

        public function get settlements():Object {
            return settlementsById;
        }

        public function reset():void {
            regions = {};
            settlementsById = {};
            settlementsByCell = {};
        }

        public function registerSettlement(cell:Cell):String {
            var id:String = UIDUtil.createUID();
            var settlement:Settlement = new Settlement(cell, id);
            cell.settlement = settlement;

            settlementsById[id] = settlement;
            settlementsByCell[cell] = settlement;

            return id;
        }

        public function registerRegion():String {
            var id:String = UIDUtil.createUID();

            regions[id] = {id: id, cells: new Vector.<Cell>()};

            return id;
        }

        public function addCellToRegion(cell:Cell, region:String, influence:int):void {
            if (cell.region) {
                var cells:Vector.<Cell> = regions[cell.region].cells;
                cells.removeAt(cells.indexOf(cell));
            }

            cell.region = regions[region].id;
            cell.regionInfluence = influence;
            regions[region].cells.push(cell);
        }
    }
}