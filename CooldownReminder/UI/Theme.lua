local _, NPR = ...

function NPR:InitializeTheme()
    self.theme = {
        backgroundTop = { 43 / 255, 45 / 255, 50 / 255, 1 },
        backgroundMid = { 31 / 255, 32 / 255, 36 / 255, 1 },
        backgroundBottom = { 18 / 255, 19 / 255, 22 / 255, 1 },
        timelineBackground = { 13 / 255, 14 / 255, 17 / 255, 1 },
        panelBackground = { 22 / 255, 23 / 255, 27 / 255, 0.86 },
        panelBackgroundSoft = { 1, 1, 1, 0.055 },
        sectionBackground = { 28 / 255, 29 / 255, 33 / 255, 0.92 },
        border = { 92 / 255, 96 / 255, 104 / 255, 0.92 },
        borderStrong = { 154 / 255, 158 / 255, 166 / 255, 1 },
        text = { 1, 1, 1, 1 },
        textMuted = { 0.76, 0.77, 0.79, 1 },
        textAccent = { 1, 0.74, 0.26, 1 },
        hover = { 1, 1, 1, 0.10 },
        disabled = { 0.48, 0.49, 0.52, 1 },
        cursor = { 1, 0.74, 0.26, 0.95 },
    }

    if not _G.NPRFontSmall then
        local small = CreateFont("NPRFontSmall")
        small:SetFont(STANDARD_TEXT_FONT, 11, "")
    end
    if not _G.NPRFontNormal then
        local normal = CreateFont("NPRFontNormal")
        normal:SetFont(STANDARD_TEXT_FONT, 13, "")
    end
    if not _G.NPRFontBold then
        local bold = CreateFont("NPRFontBold")
        bold:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    end
    if not _G.NPRFontTitle then
        local title = CreateFont("NPRFontTitle")
        title:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    end
end
