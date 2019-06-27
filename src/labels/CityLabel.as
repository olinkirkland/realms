package labels {
    import flash.display.Bitmap;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class CityLabel extends IconLabel {
        public function CityLabel(bitmap:Bitmap, text:String = null) {
            var background:Asset_CityLabel = new Asset_CityLabel();
            addChild(background);

            super(bitmap);

            if (!text)
                return;

            var format:TextFormat = new TextFormat(Fonts.regular, 14, 0xffffff);
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

            var hPadding:int = 10;
            var vPadding:int = 5;
            background.x = txt.x - hPadding;
            background.y = txt.y - vPadding;
            background.width = txt.width + 2 * hPadding;
            background.height = txt.height + 2 * vPadding;
        }
    }
}
