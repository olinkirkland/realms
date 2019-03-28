package {
    public class Rand {
        private var seed:Number;
        private const max:Number = 1 / int.MAX_VALUE;
        private const min:Number = -max;

        public function Rand(seed:Number = 1) {
            this.seed = seed;
            // Deal with zeroes
            if (seed < 1)
                seed *= 9999;
            // Deal with negatives
            if (seed < 1)
                seed = 1;
        }

        public function next():Number {
            seed ^= (seed << 21);
            seed ^= (seed >>> 35);
            seed ^= (seed << 4);
            if (seed > 0) return seed * max;
            return seed * min;
        }

        public function between(start:Number, end:Number):Number {
            return (next() * (end - start)) + start;
        }
    }
}