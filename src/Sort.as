package {
    import graph.Cell;

    public class Sort {
        public static function sortByLowestElevation(n1:Cell, n2:Cell):Number {
            if (n1.elevation > n2.elevation)
                return 1;
            else if (n1.elevation < n2.elevation)
                return -1;
            else
                return 0;
        }

        public static function sortByHighestElevation(n1:Cell, n2:Cell):Number {
            if (n1.elevation < n2.elevation)
                return 1;
            else if (n1.elevation > n2.elevation)
                return -1;
            else
                return 0;
        }

        public static function sortByDesirability(n1:Cell, n2:Cell):Number {
            if (n1.desirability < n2.desirability)
                return 1;
            else if (n1.desirability > n2.desirability)
                return -1;
            else
                return 0;
        }

        public static function sortByCellCount(n1:Object, n2:Object):Number {
            if (n1.cells.length < n2.cells.length)
                return 1;
            else if (n1.cells.length > n2.cells.length)
                return -1;
            else
                return 0;
        }
    }
}
