module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      'react-native-reanimated/plugin', // 👈 這是為了讓拖曳動畫能運作的關鍵
    ],
  };
};