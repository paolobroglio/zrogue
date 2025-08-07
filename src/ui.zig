const rl = @import("raylib");

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
        self.is_pressed = self.is_hovered and rl.isMouseButtonPressed(.mouse_button_left);
    }

    pub fn render(self: *const Button) void {
        const bg_color = if (self.is_hovered) rl.Color.dark_gray else rl.Color.gray;
        const text_color = if (self.is_hovered) rl.Color.white else rl.Color.light_gray;

        rl.drawRectangleRec(self.rect, bg_color);
        rl.drawRectangleLinesEx(self.rect, 2, rl.Color.white);

        // Center text in button
        const font_size = 20;
        const text_width = rl.measureText(self.text.ptr, font_size);
        const text_x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2.0;
        const text_y = self.rect.y + (self.rect.height - font_size) / 2.0;

        rl.drawText(self.text.ptr, @intFromFloat(text_x), @intFromFloat(text_y), font_size, text_color);
    }
};

pub const MainMenuUI = struct {
    main_menu_play_button: Button,
    main_menu_quit_button: Button,

    pub fn init() MainMenuUI {}
};

pub const PauseMenuUI = struct {
    pause_menu_resume_button: Button,
    pause_menu_options_button: Button,
    pause_menu_main_menu_button: Button,
};

pub const GameOverUI = struct {
    game_over_restart_button: Button,
    game_over_main_menu_button: Button,
};
