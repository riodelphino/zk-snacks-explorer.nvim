local sources = require("snacks.picker.config.sources")
local explorer = require("snacks.explorer")
local format = require("snacks.picker.format")
local zk_format = require("snacks.zk.format")
local zk_config = require("snacks.zk.config")
local M = {}

function M.show_zk()
   vim.notify("zk dayo!", vim.log.levels.INFO)
end

-- lua/snacks/picker/zk/init.lua           : このファイル
-- lua/snacks/explorer/init.lua            : エントリーポイント。ユーザー利用のインターフェースを提供
--                                         : action.lua / diagnositics.lua / git.lua / tree.lua / watch.lua
-- lua/snacks/picker/source/explorer.lua   :
--                                         : ツリー型ファイル探索
--                                         :    ファイルシステムをツリー構造で表示・操作
--                                         :    ディレクトリの開閉状態を管理
--                                         :    階層的なファイル表示（親子関係の追跡）
--                                         : 統合機能
--                                         :    Git 統合: ファイルの変更状態を表示
--                                         :    診断統合: LSP の診断情報を表示
--                                         :    自動更新: ファイル変更、ディレクトリ変更、診断変更を検知して更新
--                                         :    カスタムマッチャー: 検索時に親ディレクトリも自動的にマッチに含める
--                                         : search   関数 = ツリー構造でファイルを検索
--                                         : explorer 関数 = ツリー構造でファイルを表示

-- Based on explorer
-- M = vim.tbl_deep_extend("force", explorer, M) -- DEBUG: lua/snacks/picker/izk

-- M.setup()
-- M.open()
-- M.reveal()

-- OK
-- :lua require('snacks.zk').show_zk()
-- :lua require('snacks.zk').setup()
-- :lua require('snacks.zk').open()
-- :lua require('snacks.zk').reveal()

-- Add zk-explorer config
sources = vim.tbl_deep_extend("force", sources, zk_config)
print("sources: " .. vim.inspect(sources))

-- Add zk_config
format = vim.tbl_deep_extend("force", format, zk_format)

-- TODO: zk -> zk_explorer などに改名が必要か？

return M
