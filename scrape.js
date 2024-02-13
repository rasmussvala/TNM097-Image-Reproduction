const puppeteer = require("puppeteer");
const fs = require("fs");
const path = require("path");
const fetch = require("node-fetch");

async function scrape() {
  // Load browser and go to page
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto("https://pokemondb.net/pokedex/national", {
    waitUntil: "networkidle2",
  });

  // Create a storage directory (if it doesn't exist)
  const downloadDir = "./pokemon-images";
  fs.mkdirSync(downloadDir, { recursive: true });

  // Evaluate XPath expression in browser context
  const imageUrl = await page.evaluate(() => {
    const imageElement = document.evaluate(
      "/html/body/main/div[3]/div[1]/span[1]/a/picture/img",
      document,
      null,
      XPathResult.FIRST_ORDERED_NODE_TYPE,
      null
    ).singleNodeValue;
    return imageElement.src;
  });

  // Fetch the image
  const response = await fetch(imageUrl);
  const imageBuffer = await response.buffer();

  // Choose a filename for the image
  const filename = path.basename(imageUrl);
  const filepath = path.join(downloadDir, filename);

  // Save the image
  fs.writeFileSync(filepath, imageBuffer);

  await browser.close();
}

scrape();
