{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      dap = {
        enable = true;

        extensions = {
          dap-go = {
            enable = true;
            settings = {
              dap_configurations = [
                {
                  type = "go";
                  name = "Debug Package";
                  request = "launch";
                  program = "\${filedir}";
                }
                {
                  type = "go";
                  name = "Debug Test";
                  request = "launch";
                  mode = "test";
                  program = "\${file}";
                }
                {
                  type = "go";
                  name = "Debug Test (go.mod)";
                  request = "launch";
                  mode = "test";
                  program = "./\${relativeFileDirname}";
                }
              ];
            };
          };

          dap-ui = {
            enable = true;
            settings = {
              icons = { expanded = "▾"; collapsed = "▸"; current_frame = "▸"; };
              layouts = [
                {
                  elements = [
                    { id = "scopes"; size = 0.25; }
                    { id = "breakpoints"; size = 0.25; }
                    { id = "stacks"; size = 0.25; }
                    { id = "watches"; size = 0.25; }
                  ];
                  position = "left";
                  size = 40;
                }
                {
                  elements = [
                    { id = "repl"; size = 0.5; }
                    { id = "console"; size = 0.5; }
                  ];
                  position = "bottom";
                  size = 10;
                }
              ];
            };
          };

          dap-virtual-text.enable = true;
        };

        signs = {
          dapBreakpoint = { text = "●"; texthl = "DapBreakpoint"; };
          dapBreakpointCondition = { text = "●"; texthl = "DapBreakpointCondition"; };
          dapLogPoint = { text = "◆"; texthl = "DapLogPoint"; };
          dapStopped = { text = "▶"; texthl = "DapStopped"; linehl = "DapStopped"; numhl = "DapStopped"; };
        };
      };
    };

    keymaps = [
      { mode = "n"; key = "<leader>db"; action.__raw = ''function() require("dap").toggle_breakpoint() end''; options.desc = "Toggle Breakpoint"; }
      { mode = "n"; key = "<leader>dB"; action.__raw = ''function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end''; options.desc = "Conditional Breakpoint"; }
      { mode = "n"; key = "<leader>dc"; action.__raw = ''function() require("dap").continue() end''; options.desc = "Continue"; }
      { mode = "n"; key = "<leader>dC"; action.__raw = ''function() require("dap").run_to_cursor() end''; options.desc = "Run to Cursor"; }
      { mode = "n"; key = "<leader>di"; action.__raw = ''function() require("dap").step_into() end''; options.desc = "Step Into"; }
      { mode = "n"; key = "<leader>do"; action.__raw = ''function() require("dap").step_over() end''; options.desc = "Step Over"; }
      { mode = "n"; key = "<leader>dO"; action.__raw = ''function() require("dap").step_out() end''; options.desc = "Step Out"; }
      { mode = "n"; key = "<leader>dp"; action.__raw = ''function() require("dap").pause() end''; options.desc = "Pause"; }
      { mode = "n"; key = "<leader>dr"; action.__raw = ''function() require("dap").repl.toggle() end''; options.desc = "Toggle REPL"; }
      { mode = "n"; key = "<leader>ds"; action.__raw = ''function() require("dap").session() end''; options.desc = "Session"; }
      { mode = "n"; key = "<leader>dt"; action.__raw = ''function() require("dap").terminate() end''; options.desc = "Terminate"; }
      { mode = "n"; key = "<leader>du"; action.__raw = ''function() require("dapui").toggle() end''; options.desc = "Toggle DAP UI"; }
      { mode = [ "n" "v" ]; key = "<leader>de"; action.__raw = ''function() require("dapui").eval_expression() end''; options.desc = "Evaluate expression"; }
      { mode = "n"; key = "<leader>dT"; action.__raw = ''function() require("dap-go").debug_test() end''; options.desc = "Debug test (Go)"; }
      { mode = "n"; key = "<leader>dR"; action.__raw = ''function() require("dap").restart() end''; options.desc = "Restart"; }
      { mode = "n"; key = "<leader>dx"; action.__raw = ''function() require("dap").clear_breakpoints() end''; options.desc = "Clear breakpoints"; }
      { mode = "n"; key = "<leader>dl"; action.__raw = ''function() require("dap").run_last() end''; options.desc = "Run last"; }
    ];

    extraConfigLua = ''
      -- Auto open/close DAP UI
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    '';

    extraPackages = with pkgs; [
      delve
    ];
  };
}
