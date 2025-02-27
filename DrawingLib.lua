if ESP then
    ESP.Enabled = false
    ESP:Clear()
    if ESP.Updater then
        ESP.Updater:Disconnect()
    end
end

getgenv().ESP = {
    Enabled = true,

    TextSize = 18, -- default 17
    
    Objects = {}
}

repeat task.wait() until game:IsLoaded()

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function Draw(Object, Table)
    local New = Drawing.new(Object)

    Table = Table or {}
    for _,v in pairs(Table) do
        New[_] = v 
    end

    return New
end

local function WTVP(Part, WorldOffset)
    local WorldOffset = WorldOffset or Vector3.new(0,0,0)
    local Vector, See = Camera:WorldToViewportPoint(Part.Position+WorldOffset)
    return {Vector, See}
end

function ESP:Clear(object)
    local ObjectTable = self.Objects[object]
    if not object then
        for Part, PartTable in pairs(self.Objects) do
            for DrawName, DrawTable  in pairs(PartTable.Parts) do
                local Drawing = DrawTable.Drawing
                Drawing:Remove()
                self.Objects[Part] = nil
            end
        end
    else
        if ObjectTable and ObjectTable.Parts then
            for DrawName, Drawing  in pairs(ObjectTable.Parts) do
                Drawing.Drawing.Visible = false
                Drawing.Drawing.Transparency = 1
                Drawing.Drawing:Destroy()
            end
            ObjectTable = nil
        end
    end
end

function ESP:Update()
    for Part, PartTable in pairs(self.Objects) do
        task.spawn(function()
            local Worked, Error = pcall(function()
                for DrawName, DrawTable  in pairs(PartTable.Parts) do
                    local Continue = false

                    if Part and PartTable and DrawName and DrawTable and PartTable.Part and PartTable.Part.Parent then
                        Continue = true
                    else
                        Continue = false
                        if self.Objects[Part] ~= nil then 
                            ESP:Clear(Part)
                        end
                    end

                    if not Continue then break end
                        
                    local Info = DrawTable.Information
                    local Drawing = DrawTable.Drawing

                    if self.Enabled then
                        if Info.Type == "Text" then
                            local WorldOffset = PartTable.WorldOffset or Vector3.new(0,0,0)
                            local Point = WTVP(PartTable.Part, WorldOffset)
                            local Pos = Point[1]
                            if Point[2] then
                                local AddedOffset =  Info.Offset or Vector2.new(0,0,0)
                                Drawing.Text = Info.Text or "retard, put in a Name"
                                Drawing.Visible = PartTable.Enabled or false
                                Drawing.Position = Vector2.new(Pos.X, Pos.Y) + AddedOffset
                            else
                                Drawing.Visible = false
                            end
                        end
                    else
                        Drawing.Visible = false
                        break
                    end

                end
            end)

            if not Worked then
                --print(Error)
            end
        end)
    end
    return
end

function ESP:Add(Table)
    local ObjectTable = self.Objects[Table.Part]
    if ObjectTable then
        self:Clear(Table.Part)
    end

    local Everything = {
        Part = Table.Part,
        Enabled = Table.Enabled or true,
        Offset = Table.Offset or Vector2.new(0,0,0),
        WorldOffset = Table.WorldOffset or Vector3.new(0,0,0),

        Parts = {}
    }

    self.Objects[Table.Part] = {}

    self.Objects[Table.Part] = Everything

    for Name, TypeTable in pairs(Table.Parts) do

        if TypeTable.Type == "Text" then
            local Pos = WTVP(Table.Part)[1]
            Everything.Parts[Name] = {Information = nil, Drawing = nil}
            Everything.Parts[Name]["Information"] = TypeTable
            Everything.Parts[Name]["Drawing"] = Draw("Text", {
                Text = TypeTable.Text or "retard, put in a Name",
                Size = self.TextSize,
                Center = true,
                Outline = TypeTable.Outline or true,
                Visible = Table.Enabled or true,
                Color = TypeTable.Color,
                Position = Vector2.new(Pos.X, Pos.Y)
            })
        end

    end

    return Everything
end

ESP.Updater = RunService.RenderStepped:Connect(function()
    ESP:Update()
end)
