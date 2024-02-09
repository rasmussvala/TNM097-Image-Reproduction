const puppeteer = require("puppeteer");
// const fs = require("fs");
// const path = require("path");

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  await page.goto("https://www.pokemon.com/us/pokedex");

  // Wait for the page to load
  const temp = await page.waitForSelector("div.container.pokedex");

  console.log(temp);

  await browser.close();
})();
