--Hidden Devs Submission Discord @etreon.dev
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Vide = require(Packages:WaitForChild("vide"))
local Theme = require(script.Parent.Parent.Utils.ToolbarTheme)

local cleanup = Vide.cleanup
local create = Vide.create
local source = Vide.source

type Source<T> = () -> T --this is a placeholder type for reactive values
type TweenGoal = { [string]: any }

export type Props = {
	--these are all the things this toolbar button needs

	Name: Source<string>,
	Icon: Source<string>,
	Hotkey: Source<string?>,
	Compact: Source<boolean>,
	Equipped: Source<boolean>,
	Activated: () -> (),
	LayoutOrder: number,
}

local showButtonChrome = false --optional for a more minimal look

local pressTweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local popTweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local dipTweenInfo = TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local settleTweenInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local shineTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getButtonPressScale(isCompact: boolean): number
	return if isCompact then 0.86 else 0.88
end

local function getIconPressScale(isCompact: boolean): number
	return if isCompact then 0.9 else 0.92
end

--function for making and playing tweens
local function playTween(activeTweens: { Tween }, instance: Instance, tweenInfo: TweenInfo, goal: TweenGoal): Tween
	local tween = TweenService:Create(instance, tweenInfo, goal)

	table.insert(activeTweens, tween)
	tween:Play() 

	return tween
end

-- this cancels every currently running tween in the list
local function cancelTweens(activeTweens: { Tween })
	for _, tween in activeTweens do
		tween:Cancel()
	end

	table.clear(activeTweens)
end

--this function builds the toolbar buttons aka the main component
local function ToolbarButton(props: Props)
	--state for interactive hover and clicks
	local hovered = source(false)
	local pressed = source(false)

	--active tweens live are handled in this table so new animations can cancel old ones
	local activeTweens = {} :: { Tween }

	--we check this so old clicks dont overlap new clicks
	local animationToken = 0

	local function nextAnimation(): number
		animationToken += 1
		cancelTweens(activeTweens)

		return animationToken
	end

	local function isCurrentAnimation(token: number): boolean
		return token == animationToken
	end

	local function getHotkeyText(): string
		return props.Hotkey() or ""
	end

	local function getPlateColor(): Color3
		if props.Equipped() then
			return Theme.ButtonEquipped
		end

		if hovered() then
			return Theme.ButtonHover
		end

		return Theme.ButtonIdle
	end

	local function getPlateTransparency(): number
		if not showButtonChrome then
			return 1
		end

		if props.Equipped() then
			return 0.05
		end

		if pressed() then
			return 0.1
		end

		if hovered() then
			return 0.14
		end

		return 0.22
	end

	local function getShadowTransparency(): number
		if not showButtonChrome then
			return 1
		end

		if props.Equipped() then
			return 0.35
		end

		if hovered() then
			return 0.48
		end

		return 0.62
	end

	local function getPlateGradient(): ColorSequence
		if props.Equipped() then
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Theme.AccentSoft),
				ColorSequenceKeypoint.new(0.4, Theme.ButtonEquipped),
				ColorSequenceKeypoint.new(1, Theme.ButtonEquippedDeep),
			})
		end

		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.RailEdge),
			ColorSequenceKeypoint.new(0.5, Theme.ButtonIdle),
			ColorSequenceKeypoint.new(1, Theme.Background),
		})
	end

	local function getGradientTransparency(): NumberSequence
		if not showButtonChrome then
			return NumberSequence.new(1)
		end

		if props.Equipped() then
			return NumberSequence.new(0.08)
		end

		return NumberSequence.new(0.16)
	end

	local scale = create("UIScale") {
		Scale = 1,
	}

	local iconScale = create("UIScale") {
		Scale = 1,
	}
	-- this is the shadow frame behind the button
	local shadow = create("Frame") {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Shadow,
		BackgroundTransparency = getShadowTransparency,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromScale(1.08, 1.12),
		ZIndex = 0,

		create("UICorner") {
			CornerRadius = UDim.new(0.28, 0),
		},
	}

	local shine = create("Frame") {
		Name = "Shine",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.AccentSoft,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.15, 1.15),
		ZIndex = 3,

		create("UICorner") {
			CornerRadius = UDim.new(0.28, 0),
		},
	}

	local plate = create("Frame") {
		Name = "Plate",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = getPlateColor,
		BackgroundTransparency = getPlateTransparency,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = function()
			if props.Compact() then
				return UDim2.fromOffset(90, 90)
			end

			return UDim2.fromOffset(110, 110)
		end,
		ZIndex = 2,

		create("UICorner") {
			CornerRadius = UDim.new(0.28, 0),
		},

		create("UIGradient") {
			Color = getPlateGradient,
			Rotation = 115,
			Transparency = getGradientTransparency,
		},

		create("UIAspectRatioConstraint") {
			AspectRatio = 1,
			AspectType = Enum.AspectType.FitWithinMaxSize,
			DominantAxis = Enum.DominantAxis.Height,
		},
	}

	local button: TextButton

	local function playPressAnimation()
		local isCompact = props.Compact()
		local token = nextAnimation()

		pressed(true)

		playTween(activeTweens, scale, pressTweenInfo, {
			Scale = getButtonPressScale(isCompact),
		})

		playTween(activeTweens, iconScale, pressTweenInfo, {
			Scale = getIconPressScale(isCompact),
		})

		playTween(activeTweens, button, pressTweenInfo, {
			Rotation = -4,
		})

		task.delay(0.12, function()
			if isCurrentAnimation(token) then
				table.clear(activeTweens)
			end
		end)
	end

	local function playCancelAnimation()
		local token = nextAnimation()

		pressed(false)

		playTween(activeTweens, scale, settleTweenInfo, {
			Scale = 1,
		})

		playTween(activeTweens, iconScale, settleTweenInfo, {
			Scale = 1,
		})

		playTween(activeTweens, button, settleTweenInfo, {
			Rotation = 0,
		})

		if showButtonChrome then
			playTween(activeTweens, shine, shineTweenInfo, {
				BackgroundTransparency = 1,
			})
		end

		task.delay(0.22, function()
			if isCurrentAnimation(token) then
				table.clear(activeTweens)
			end
		end)
	end

	local function playReleaseAnimation()
		local isCompact = props.Compact()
		local token = nextAnimation()

		pressed(false)

		scale.Scale = getButtonPressScale(isCompact)
		iconScale.Scale = getIconPressScale(isCompact)
		button.Rotation = -4

		if showButtonChrome then
			shine.BackgroundTransparency = 0.72
		else
			shine.BackgroundTransparency = 1
		end

		playTween(activeTweens, scale, popTweenInfo, {
			Scale = if isCompact then 1.18 else 1.16,
		})

		playTween(activeTweens, iconScale, popTweenInfo, {
			Scale = if isCompact then 1.2 else 1.18,
		})

		playTween(activeTweens, button, popTweenInfo, {
			Rotation = 6,
		})

		if showButtonChrome then
			playTween(activeTweens, shine, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			})
		end

		task.delay(0.14, function()
			if not isCurrentAnimation(token) then
				return
			end

			playTween(activeTweens, scale, dipTweenInfo, {
				Scale = 0.96,
			})

			playTween(activeTweens, iconScale, dipTweenInfo, {
				Scale = 0.97,
			})

			playTween(activeTweens, button, dipTweenInfo, {
				Rotation = -2,
			})
		end)

		task.delay(0.3, function()
			if not isCurrentAnimation(token) then
				return
			end

			playTween(activeTweens, scale, popTweenInfo, {
				Scale = 1.02,
			})

			playTween(activeTweens, iconScale, popTweenInfo, {
				Scale = 1.03,
			})

			playTween(activeTweens, button, popTweenInfo, {
				Rotation = 1,
			})
		end)

		task.delay(0.46, function()
			if not isCurrentAnimation(token) then
				return
			end

			playTween(activeTweens, scale, settleTweenInfo, {
				Scale = 1,
			})

			playTween(activeTweens, iconScale, settleTweenInfo, {
				Scale = 1,
			})

			playTween(activeTweens, button, settleTweenInfo, {
				Rotation = 0,
			})

			if showButtonChrome then
				playTween(activeTweens, shine, shineTweenInfo, {
					BackgroundTransparency = 1,
				})
			end
		end)

		task.delay(0.68, function()
			if isCurrentAnimation(token) then
				table.clear(activeTweens)
			end
		end)
	end

	button = create("TextButton") {
		Name = function()
			return props.Name() .. "Button"
		end,

		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		LayoutOrder = props.LayoutOrder,
		Rotation = 0,
		Size = function()
			return Theme.GetButtonSize(props.Compact())
		end,
		Text = "",
		ZIndex = 2,

		Activated = function()
			playReleaseAnimation()
			props.Activated()
		end,

		MouseButton1Down = function()
			playPressAnimation()
		end,

		MouseButton1Up = function()
			pressed(false)
		end,

		MouseEnter = function()
			hovered(true)
		end,

		MouseLeave = function()
			hovered(false)

			if pressed() then
				playCancelAnimation()
			else
				pressed(false)
			end
		end,

		shadow,
		shine,
		scale,
		plate,

		create("ImageLabel") {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.Icon,
			ImageTransparency = 0,
			ScaleType = Enum.ScaleType.Fit,
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = function()
				if props.Compact() then
					return UDim2.fromOffset(96, 96)
				end

				return UDim2.fromOffset(148, 148)
			end,
			ZIndex = 4,

			iconScale,
		},

		create("TextLabel") {
			Name = "Hotkey",
			AnchorPoint = Vector2.new(1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Position = function()
				if props.Compact() then
					return UDim2.fromOffset(86, -16)
				end

				return UDim2.fromOffset(114, -18)
			end,
			Size = UDim2.fromOffset(0, 46),
			Font = Enum.Font.FredokaOne,
			Text = getHotkeyText,
			TextColor3 = Theme.Outline,
			TextSize = 38,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Right,
			Visible = function()
				return not props.Compact() and getHotkeyText() ~= ""
			end,
			ZIndex = 5,

			create("UIStroke") {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				Color = Color3.fromRGB(0, 0, 0),
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = 5,
				Transparency = 0,
			},
		},
	}

	--on clean up it will stop any active tweens and disconnect connections
	cleanup(function()
		animationToken += 1
		cancelTweens(activeTweens)
	end)

	return button
end

return ToolbarButton
