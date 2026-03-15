const w32 = @import("win32.zig");
const UINT = w32.UINT;
const IUnknown = w32.IUnknown;
const GUID = w32.GUID;
const HRESULT = w32.HRESULT;
const WINAPI = w32.WINAPI;
const LPCWSTR = w32.LPCWSTR;
const FLOAT = w32.FLOAT;
const UINT32 = w32.UINT32;
const WCHAR = w32.WCHAR;

pub const MEASURING_MODE = enum(UINT) {
    NATURAL = 0,
    GDI_CLASSIC = 1,
    GDI_NATURAL = 2,
};

pub const FONT_WEIGHT = enum(UINT) {
    THIN = 100,
    EXTRA_LIGHT = 200,
    LIGHT = 300,
    SEMI_LIGHT = 350,
    NORMAL = 400,
    MEDIUM = 500,
    SEMI_BOLD = 600,
    BOLD = 700,
    EXTRA_BOLD = 800,
    HEAVY = 900,
    ULTRA_BLACK = 950,
};

pub const FONT_STRETCH = enum(UINT) {
    UNDEFINED = 0,
    ULTRA_CONDENSED = 1,
    EXTRA_CONDENSED = 2,
    CONDENSED = 3,
    SEMI_CONDENSED = 4,
    NORMAL = 5,
    SEMI_EXPANDED = 6,
    EXPANDED = 7,
    EXTRA_EXPANDED = 8,
    ULTRA_EXPANDED = 9,
};

pub const FONT_STYLE = enum(UINT) {
    NORMAL = 0,
    OBLIQUE = 1,
    ITALIC = 2,
};

pub const FACTORY_TYPE = enum(UINT) {
    SHARED = 0,
    ISOLATED = 1,
};

pub const TEXT_ALIGNMENT = enum(UINT) {
    LEADING = 0,
    TRAILING = 1,
    CENTER = 2,
    JUSTIFIED = 3,
};

pub const PARAGRAPH_ALIGNMENT = enum(UINT) {
    NEAR = 0,
    FAR = 1,
    CENTER = 2,
};

pub const TEXT_METRICS = extern struct {
    left: FLOAT,
    top: FLOAT,
    width: FLOAT,
    widthIncludingTrailingWhitespace: FLOAT,
    height: FLOAT,
    layoutWidth: FLOAT,
    layoutHeight: FLOAT,
    maxBidiReorderingDepth: UINT32,
    lineCount: UINT32,
};

pub const IFontCollection = extern struct {
    __v: *const VTable,

    pub const QueryInterface = IUnknown.Methods(@This()).QueryInterface;
    pub const AddRef = IUnknown.Methods(@This()).AddRef;
    pub const Release = IUnknown.Methods(@This()).Release;

    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetFontFamilyCount: *anyopaque,
        GetFontFamily: *anyopaque,
        FindFamilyName: *anyopaque,
        GetFontFromFontFace: *anyopaque,
    };
};

pub const ITextFormat = extern struct {
    __v: *const VTable,

    pub const QueryInterface = IUnknown.Methods(@This()).QueryInterface;
    pub const AddRef = IUnknown.Methods(@This()).AddRef;
    pub const Release = IUnknown.Methods(@This()).Release;

    pub const SetTextAlignment = ITextFormat.Methods(@This()).SetTextAlignment;
    pub const SetParagraphAlignment = ITextFormat.Methods(@This()).SetParagraphAlignment;
    pub const GetFontFamilyName = ITextFormat.Methods(@This()).GetFontFamilyName;

    pub fn Methods(comptime T: type) type {
        return extern struct {
            pub inline fn SetTextAlignment(self: *T, alignment: TEXT_ALIGNMENT) HRESULT {
                return @as(*const ITextFormat.VTable, @ptrCast(self.__v))
                    .SetTextAlignment(@ptrCast(self), alignment);
            }
            pub inline fn SetParagraphAlignment(self: *T, alignment: PARAGRAPH_ALIGNMENT) HRESULT {
                return @as(*const ITextFormat.VTable, @ptrCast(self.__v))
                    .SetParagraphAlignment(@ptrCast(self), alignment);
            }
            pub inline fn GetFontFamilyName(self: *T, name: [*:0]WCHAR, name_size: UINT32) HRESULT {
                return @as(*const ITextFormat.VTable, @ptrCast(self.__v))
                    .GetFontFamilyName(@ptrCast(self), name, name_size);
            }
        };
    }

    pub const VTable = extern struct {
        base: IUnknown.VTable,
        SetTextAlignment: *const fn (*ITextFormat, TEXT_ALIGNMENT) callconv(WINAPI) HRESULT,
        SetParagraphAlignment: *const fn (*ITextFormat, PARAGRAPH_ALIGNMENT) callconv(WINAPI) HRESULT,
        SetWordWrapping: *anyopaque,
        SetReadingDirection: *anyopaque,
        SetFlowDirection: *anyopaque,
        SetIncrementalTabStop: *anyopaque,
        SetTrimming: *anyopaque,
        SetLineSpacing: *anyopaque,
        GetTextAlignment: *anyopaque,
        GetParagraphAlignment: *anyopaque,
        GetWordWrapping: *anyopaque,
        GetReadingDirection: *anyopaque,
        GetFlowDirection: *anyopaque,
        GetIncrementalTabStop: *anyopaque,
        GetTrimming: *anyopaque,
        GetLineSpacing: *anyopaque,
        GetFontCollection: *anyopaque,
        GetFontFamilyNameLength: *anyopaque,
        GetFontFamilyName: *const fn (*ITextFormat, [*:0]WCHAR, UINT32) callconv(WINAPI) HRESULT,
        GetFontWeight: *anyopaque,
        GetFontStyle: *anyopaque,
        GetFontStretch: *anyopaque,
        GetFontSize: *anyopaque,
        GetLocaleNameLength: *anyopaque,
        GetLocaleName: *anyopaque,
    };
};

pub const ITextLayout = extern struct {
    __v: *const VTable,

    pub const QueryInterface = IUnknown.Methods(@This()).QueryInterface;
    pub const AddRef = IUnknown.Methods(@This()).AddRef;
    pub const Release = IUnknown.Methods(@This()).Release;

    pub const SetTextAlignment = ITextFormat.Methods(@This()).SetTextAlignment;
    pub const SetParagraphAlignment = ITextFormat.Methods(@This()).SetParagraphAlignment;
    pub const GetMaxWidth = ITextLayout.Methods(@This()).GetMaxWidth;
    pub const GetMaxHeight = ITextLayout.Methods(@This()).GetMaxHeight;
    pub const GetMetrics = ITextLayout.Methods(@This()).GetMetrics;

    pub fn Methods(comptime T: type) type {
        return extern struct {
            pub inline fn GetMaxWidth(self: *T) FLOAT {
                return @as(*const ITextLayout.VTable, @ptrCast(self.__v)).GetMaxWidth(@ptrCast(self));
            }
            pub inline fn GetMaxHeight(self: *T) FLOAT {
                return @as(*const ITextLayout.VTable, @ptrCast(self.__v)).GetMaxHeight(@ptrCast(self));
            }
            pub inline fn GetMetrics(self: *T, metrics: *TEXT_METRICS) HRESULT {
                return @as(*const ITextLayout.VTable, @ptrCast(self.__v)).GetMetrics(@ptrCast(self), metrics);
            }
        };
    }

    pub const VTable = extern struct {
        base: ITextFormat.VTable,
        SetMaxWidth: *anyopaque,
        SetMaxHeight: *anyopaque,
        SetFontCollection: *anyopaque,
        SetFontFamilyName: *anyopaque,
        SetFontWeight: *anyopaque,
        SetFontStyle: *anyopaque,
        SetFontStretch: *anyopaque,
        SetFontSize: *anyopaque,
        SetUnderline: *anyopaque,
        SetStrikethrough: *anyopaque,
        SetDrawingEffect: *anyopaque,
        SetInlineObject: *anyopaque,
        SetTypography: *anyopaque,
        SetLocaleName: *anyopaque,
        GetMaxWidth: *const fn (*ITextLayout) callconv(WINAPI) FLOAT,
        GetMaxHeight: *const fn (*ITextLayout) callconv(WINAPI) FLOAT,
        GetFontCollection: *anyopaque,
        GetFontFamilyNameLength: *anyopaque,
        GetFontFamilyName: *anyopaque,
        GetFontWeight: *anyopaque,
        GetFontStyle: *anyopaque,
        GetFontStretch: *anyopaque,
        GetFontSize: *anyopaque,
        GetUnderline: *anyopaque,
        GetStrikethrough: *anyopaque,
        GetDrawingEffect: *anyopaque,
        GetInlineObject: *anyopaque,
        GetTypography: *anyopaque,
        GetLocaleNameLength: *anyopaque,
        GetLocaleName: *anyopaque,
        Draw: *anyopaque,
        GetLineMetrics: *anyopaque,
        GetMetrics: *const fn (*ITextLayout, *TEXT_METRICS) callconv(WINAPI) HRESULT,
        GetOverhangMetrics: *anyopaque,
        GetClusterMetrics: *anyopaque,
        DetermineMinWidth: *anyopaque,
        HitTestPoint: *anyopaque,
        HitTestTextPosition: *anyopaque,
        HitTestTextRange: *anyopaque,
    };
};

pub const IFactory = extern struct {
    __v: *const VTable,

    pub const IID = GUID.parse("{b859ee5a-d838-4b5b-a2e8-1adc7d93db48}");

    pub const QueryInterface = IUnknown.Methods(@This()).QueryInterface;
    pub const AddRef = IUnknown.Methods(@This()).AddRef;
    pub const Release = IUnknown.Methods(@This()).Release;

    pub const CreateTextFormat = IFactory.Methods(@This()).CreateTextFormat;
    pub const CreateTextLayout = IFactory.Methods(@This()).CreateTextLayout;

    pub fn Methods(comptime T: type) type {
        return extern struct {
            pub inline fn CreateTextFormat(
                self: *T,
                font_family_name: LPCWSTR,
                font_collection: ?*IFontCollection,
                font_weight: FONT_WEIGHT,
                font_style: FONT_STYLE,
                font_stretch: FONT_STRETCH,
                font_size: FLOAT,
                locale_name: LPCWSTR,
                text_format: *?*ITextFormat,
            ) HRESULT {
                return @as(*const IFactory.VTable, @ptrCast(self.__v)).CreateTextFormat(
                    @ptrCast(self),
                    font_family_name,
                    font_collection,
                    font_weight,
                    font_style,
                    font_stretch,
                    font_size,
                    locale_name,
                    text_format,
                );
            }
            pub inline fn CreateTextLayout(
                self: *T,
                string: LPCWSTR,
                string_length: UINT32,
                text_format: *ITextFormat,
                max_width: FLOAT,
                max_height: FLOAT,
                text_layout: *?*ITextLayout,
            ) HRESULT {
                return @as(*const IFactory.VTable, @ptrCast(self.__v)).CreateTextLayout(
                    @ptrCast(self),
                    string,
                    string_length,
                    text_format,
                    max_width,
                    max_height,
                    text_layout,
                );
            }
        };
    }

    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetSystemFontCollection: *anyopaque,
        CreateCustomFontCollection: *anyopaque,
        RegisterFontCollectionLoader: *anyopaque,
        UnregisterFontCollectionLoader: *anyopaque,
        CreateFontFileReference: *anyopaque,
        CreateCustomFontFileReference: *anyopaque,
        CreateFontFace: *anyopaque,
        CreateRenderingParams: *anyopaque,
        CreateMonitorRenderingParams: *anyopaque,
        CreateCustomRenderingParams: *anyopaque,
        RegisterFontFileLoader: *anyopaque,
        UnregisterFontFileLoader: *anyopaque,
        CreateTextFormat: *const fn (
            *IFactory,
            LPCWSTR,
            ?*IFontCollection,
            FONT_WEIGHT,
            FONT_STYLE,
            FONT_STRETCH,
            FLOAT,
            LPCWSTR,
            *?*ITextFormat,
        ) callconv(WINAPI) HRESULT,
        CreateTypography: *anyopaque,
        GetGdiInterop: *anyopaque,
        CreateTextLayout: *const fn (
            *IFactory,
            LPCWSTR,
            UINT32,
            *ITextFormat,
            FLOAT,
            FLOAT,
            *?*ITextLayout,
        ) callconv(WINAPI) HRESULT,
        CreateGdiCompatibleTextLayout: *anyopaque,
        CreateEllipsisTrimmingSign: *anyopaque,
        CreateTextAnalyzer: *anyopaque,
        CreateNumberSubstitution: *anyopaque,
        CreateGlyphRunAnalysis: *anyopaque,
    };
};

pub const CreateFactory = DWriteCreateFactory;

extern "dwrite" fn DWriteCreateFactory(
    factory_type: FACTORY_TYPE,
    guid: *const GUID,
    factory: *?*anyopaque,
) callconv(WINAPI) HRESULT;

pub const E_FILEFORMAT = @as(HRESULT, @bitCast(@as(c_ulong, 0x88985000)));
