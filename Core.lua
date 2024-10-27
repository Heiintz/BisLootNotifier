BLN = {}
BLN.TRANSLATIONS = {}
BLN.CLIENT_LANGUAGE = getClientLanguageCode()
BLN.BIS_LIST_S1 = {}
BLN.UPDATE_BIS_FRAME = {}
BLN.SPEC_ICONS_LIST = {}
BLN.SPEC_ICONS = {}
BLN.SIMULATED_PLAYERS = {}
BLN.BIS_FRAME = {}
BLN.IS_DUNGEON_OR_RAID = checkIfInDungeonOrRaid()

BLN.BIS_FRAME = CreateFrame("Frame", "BiSFrame", UIParent, "BasicFrameTemplateWithInset")
BLN.BIS_FRAME:SetPoint("CENTER")
BLN.BIS_FRAME:Hide()
BLN.BIS_FRAME.title = BLN.BIS_FRAME:CreateFontString(nil, "OVERLAY")
BLN.BIS_FRAME.title:SetFontObject("GameFontHighlight")
BLN.BIS_FRAME.title:SetPoint("CENTER", BLN.BIS_FRAME.TitleBg, "CENTER", 0, 0)
BLN.BIS_FRAME.title:SetText("BiS Loot Notifier")

BLN.BIS_FRAME:SetMovable(true)
BLN.BIS_FRAME:EnableMouse(true)
BLN.BIS_FRAME:RegisterForDrag("LeftButton")
BLN.BIS_FRAME:SetScript("OnDragStart", BLN.BIS_FRAME.StartMoving)
BLN.BIS_FRAME:SetScript("OnDragStop", BLN.BIS_FRAME.StopMovingOrSizing)

local function UpdateInstanceStatus()
    BLN.IS_DUNGEON_OR_RAID = checkIfInDungeonOrRaid()
end

local frame = CreateFrame("Frame")

local function ProcessLootItem(itemId, itemType, itemSubType, simulatedLoot)
    local translations = BLN.TRANSLATIONS[BLN.CLIENT_LANGUAGE] or BLN.TRANSLATIONS["enUS"]
    if (itemType == translations.armor or itemType == translations.weapon) then
        local itemName, _, itemQuality, _, _, _, _, _, _, iconPath = GetItemInfo(itemId)
        if itemName and (itemQuality == 3 or itemQuality == 4) then
            table.insert(simulatedLoot, { itemId = itemId, itemName = itemName })
        end
    end
end

local storedLootItems = {}

local function StoreItemList()
    storedLootItems = {}  -- Réinitialise la table au début

    local numItems = GetNumLootItems()  -- Récupère le nombre d'objets dans le butin
    for i = 1, numItems do
        local itemLink = GetLootSlotLink(i)
        if itemLink then
            local itemId = tonumber(string.match(itemLink, "item:(%d+)"))
            if itemId then
                -- Ajoute l'itemId dans la table des objets sauvegardés
                table.insert(storedLootItems, itemId)
            else
                print("Invalid itemId for itemLink: ", itemLink)
            end
        end
    end
end


-- Fonction principale pour traiter le loot ouvert
local function OnLootOpened(event, autoLoot)
    -- Appelle la fonction pour sauvegarder tous les objets lootés
    StoreItemList()

    -- Met à jour les icônes des spécialisations après avoir stocké les objets
    UpdateSpecIcons()

    if (BLN.IS_DUNGEON_OR_RAID) then
        local numItems = GetNumLootItems()
        if numItems > 0 then
            local simulatedLoot = {}

            -- Utilise la liste sauvegardée pour traiter les objets lootés
            for i = 1, #storedLootItems do
                local itemId = storedLootItems[i]

                if itemId then
                    local itemType, itemSubType = select(6, GetItemInfo(itemId))
                    if itemType then
                        -- Traite l'objet avec les informations disponibles
                        ProcessLootItem(itemId, itemType, itemSubType, simulatedLoot)
                    else
                        -- Gère le cas où les informations sur l'objet ne sont pas encore disponibles
                        local frame = CreateFrame("Frame")
                        frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
                        frame:SetScript("OnEvent", function(self, event, id)
                            if id == itemId then
                                itemType, itemSubType = select(6, GetItemInfo(itemId))
                                if itemType then
                                    ProcessLootItem(itemId, itemType, itemSubType, simulatedLoot)
                                end
                                self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
                            end
                        end)
                    end
                else
                    print("Invalid itemId in storedLootItems: ", itemId)
                end
            end

            -- Si des objets simulés ont été traités, met à jour l'interface utilisateur ou autre fonction
            if #simulatedLoot > 0 then
                UpdateBiSFrame(simulatedLoot, simulatedPlayers)
            end
        end
    end
end

frame:RegisterEvent("LOOT_OPENED")
frame:SetScript("OnEvent", function(self, event, ...)
    UpdateInstanceStatus()
    if event == "LOOT_OPENED" then
        OnLootOpened(event, ...)
    end
end)


SLASH_BISLOOTNOTIFIER1 = "/bln"
SlashCmdList["BISLOOTNOTIFIER"] = function(msg)
    if msg == "test" then
        UpdateInstanceStatus()
        SimulateLoot()
    else
        print("Utilisez '/bln test' pour simuler un loot.")
    end
end
