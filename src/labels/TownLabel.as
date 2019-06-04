package labels {
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.filters.DropShadowFilter;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class TownLabel extends IconLabel {
        public function TownLabel(bitmap:Bitmap, text:String = null) {
            var background:Sprite = new Sprite();
            addChild(background);

            super(bitmap);

            if (!text)
                return;

            // todo remove this
            return;

            var format:TextFormat = new TextFormat(Fonts.regular, 10, 0x000000);
            var txt:TextField = new TextField();
            txt.embedFonts = true;
            txt.defaultTextFormat = format;
            txt.selectable = false;
            txt.text = text;
            txt.autoSize = TextFieldAutoSize.LEFT;
            txt.width = txt.textWidth;
            addChild(txt);

            txt.x = -txt.width / 2;
            txt.y = bitmap.y + 16;

            var hPadding:int = 3;
            var vPadding:int = 1;
            background.graphics.lineStyle(2, 0x000000);
            background.graphics.beginFill(0xffffff);
            background.graphics.drawRoundRect(txt.x - hPadding, txt.y - vPadding, txt.width + 2 * hPadding, txt.height + 2 * vPadding, 25, 25);
            background.graphics.endFill();
            background.cacheAsBitmap = true;
        }
    }
}
