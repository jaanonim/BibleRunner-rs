const fs = require("fs");
const path = require("path");

const booksFile = fs.readFileSync("./books/books.json", "utf-8");
let books = JSON.parse(booksFile);

const directoryPath = "./books";

fs.readdirSync(directoryPath).forEach((file) => {
    const filePath = path.join(directoryPath, file);
    const jsonData = fs.readFileSync(filePath, "utf-8");

    const data = JSON.parse(jsonData);
    for (const key in data) {
        books[key].push(...data[key]);
    }
});

const reversedBooks = {};
for (const key in books) {
    for (const value of books[key]) {
        reversedBooks[value] = key;
    }
}

console.log(reversedBooks);

let rsMapString = `use phf::phf_map;
static BOOKS: phf::Map<&'static str, &'static str> = phf_map! {\n`;

for (const key in reversedBooks) {
    rsMapString += `    "${key}" => "${reversedBooks[key]}",\n`;
}
rsMapString += `};
pub fn parse_book_name(book: &str) -> Option<&'static str> {
    BOOKS.get(book).cloned()
}`;
fs.writeFileSync("../src/books.rs", rsMapString, "utf-8");
