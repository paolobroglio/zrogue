const rl = @import("raylib");

const center_x = 640.0; // window_width / 2
const center_y = 400.0; // window_height / 2
const button_width = 200.0;
const button_height = 50.0;
const button_spacing = 60.0;

pub const Button = struct {
    rect: rl.Rectangle,
    text: []const u8,
    is_hovered: bool = false,
    is_pressed: bool = false,

    pub fn init(x: f32, y: f32, width: f32, height: f32, text: []const u8) Button {
        return Button{
            .rect = rl.Rectangle{ .x = x, .y = y, .width = width, .height = height },
            .text = text,
        };
    }

    pub fn update(self: *Button) void {
        const mouse_pos = rl.getMousePosition();
        self.is_hovered = rl.checkCollisionPointRec(mouse_pos, self.rect);
        self.is_pressed = self.is_hovered and rl.isMouseButtonPressed(rl.MouseButton.left);
    }

    pub fn render(self: *const Button) void {
        const bg_color = if (self.is_hovered) rl.Color.dark_gray else rl.Color.gray;
        const text_color = if (self.is_hovered) rl.Color.white else rl.Color.light_gray;

        rl.drawRectangleRec(self.rect, bg_color);
        rl.drawRectangleLinesEx(self.rect, 2, rl.Color.white);

        // Center text in button
        const font_size = 20;
        const text_width = rl.measureText(@ptrCast(self.text), font_size);
        const text_x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2.0;
        const text_y = self.rect.y + (self.rect.height - font_size) / 2.0;

        rl.drawText(@ptrCast(self.text), @intFromFloat(text_x), @intFromFloat(text_y), font_size, text_color);
    }
};

pub const MainMenuUI = struct {
    play_button: Button,
    quit_button: Button,

    pub fn init() MainMenuUI {
        return MainMenuUI{ 
            .play_button = Button.init(center_x - button_width / 2, center_y - button_spacing, button_width, button_height, "Play"), 
            .quit_button = Button.init(center_x - button_width / 2, center_y + button_spacing, button_width, button_height, "Quit") 
        };
    }
};

pub const PauseMenuUI = struct {
    resume_button: Button,
    options_button: Button,
    main_menu_button: Button,

    pub fn init() PauseMenuUI {
        return PauseMenuUI {
            .resume_button = Button.init(center_x - button_width/2, center_y - button_spacing, button_width, button_height, "Resume"),
            .options_button = Button.init(center_x - button_width/2, center_y, button_width, button_height, "Options"),
            .main_menu_button = Button.init(center_x - button_width/2, center_y + button_spacing, button_width, button_height, "Main Menu"),
           
        };
    }
};

pub const GameOverUI = struct {
    restart_button: Button,
    main_menu_button: Button,

    pub fn init() GameOverUI {
        return GameOverUI {
            .restart_button = Button.init(center_x - button_width/2, center_y - button_spacing/2, button_width, button_height, "Restart"),
            .main_menu_button = Button.init(center_x - button_width/2, center_y + button_spacing/2, button_width, button_height, "Main Menu"),
        };
    }
};
