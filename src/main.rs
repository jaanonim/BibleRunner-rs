use std::collections::HashMap;

use arboard::Clipboard;
use krunner::{Match, RunnerExt};
use lazy_static::lazy_static;
use regex::Regex;

lazy_static! {
    static ref linkRegex: Regex =
        Regex::new(r"([12345]\s?)?\p{L}+\s?\d{1,3}([:,.]\s?\d{1,3}(-\d{1,3})?)?").unwrap();
    static ref bookRegex: Regex = Regex::new(r"([12345]\s?)?\p{L}+").unwrap();
    static ref separatorRegex: Regex = Regex::new(r"[-:,.]+").unwrap();
    // TODO:
    // static ref htmlRegex: Regex =
    //     Regex::new(r#"<script\s*id="__NEXT_DATA__"\s*type="application\/json"\s*>.+?(?=<\/script>\s*<\/body>\s*<\/html>)"#).unwrap();
    static ref htmlDelRegex: Regex =
        Regex::new(r#"<script\s*id="__NEXT_DATA__"\s*type="application\/json"\s*>"#).unwrap();
}

#[derive(Clone, Copy)]
struct Action;
impl krunner::Action for Action {
    fn all() -> &'static [Self] {
        &[Self; 0]
    }

    fn from_id(_: &str) -> Option<Self> {
        None
    }

    fn to_id(&self) -> String {
        "".to_owned()
    }

    fn info(&self) -> krunner::ActionInfo {
        krunner::ActionInfo {
            title: "".to_owned(),
            icon: "".to_owned(),
        }
    }
}

struct Runner {
    pub results: HashMap<String, Match<Action>>,
}

impl Runner {
    fn new() -> Self {
        Runner {
            results: HashMap::new(),
        }
    }

    fn try_match(&mut self, query: String) -> Option<Vec<Match<Action>>> {
        let query = query.trim();
        if !linkRegex.is_match(query) {
            return None;
        }

        let c = linkRegex.captures(query)?;
        let text = c[0].trim();
        if text.len() != query.len() {
            return None;
        }

        let raw_book = &bookRegex.captures(query)?[0];
        let book_name: String = raw_book
            .to_lowercase()
            .trim()
            .chars()
            .filter(|c| !c.is_whitespace())
            .collect();
        //TODO: find Book
        let book = "JHN";

        let text = &text[raw_book.len()..];
        let split: Vec<&str> = separatorRegex.split(text).map(|s| s.trim()).collect();

        let mut url = get_book_url(book);
        let text = match split.len() {
            1 => {
                url += split[0];
                Some(split[0].to_owned())
            }
            2 => {
                url += &format!("{}.{}", split[0], split[1]);
                Some(format!("{}:{}", split[0], split[1]))
            }
            3 => {
                url += &format!("{}.{}-{}", split[0], split[1], split[2]);
                Some(format!("{}:{}-{}", split[0], split[1], split[2]))
            }
            _ => None,
        }?;

        self.results = HashMap::from([
            ("bible_copy".to_owned(), make_copy_match(&url)),
            (
                "bible_browser".to_owned(),
                make_browser_match(book, &text, &url),
            ),
        ]);

        Some(self.results.values().map(|ele| (*ele).clone()).collect())
    }
}

fn make_copy_match(url: &str) -> Match<Action> {
    Match {
        id: "bible_copy".to_owned(),
        title: format!("Hello there!").to_owned(),
        icon: "bible_runner".to_owned().into(),
        subtitle: Some("Copy text".to_owned()),
        multiline: true,
        ..Match::<Action>::default()
    }
}

fn make_browser_match(book: &str, text: &str, url: &str) -> Match<Action> {
    Match {
        id: "bible_browser".to_owned(),
        title: format!("Open {book} {text}").to_owned(),
        icon: "bible_runner".to_owned().into(),
        subtitle: Some("Open Bible in browser".to_owned()),
        urls: vec![url.to_owned()],
        ..Match::<Action>::default()
    }
}

fn get_book_url(book: &str) -> String {
    format!("https://www.bible.com/bible/{}/{}.", "2095", book)
}

impl krunner::Runner for Runner {
    type Action = Action;
    type Err = String;

    fn matches(&mut self, query: String) -> Result<Vec<Match<Self::Action>>, Self::Err> {
        if query.starts_with('?') {
            return Ok(vec![]);
        }

        if let Some(matches) = self.try_match(query) {
            return Ok(matches);
        }
        Ok(vec![])
    }

    fn run(&mut self, _match_id: String, _action: Option<Self::Action>) -> Result<(), Self::Err> {
        match _match_id.as_str() {
            "bible_copy" => {
                let mut clipboard = Clipboard::new().map_err(|_| " ")?;
                let text = self.results.get(&_match_id).ok_or("err")?.title.clone();
                clipboard.set_text(text).map_err(|_| " ")?;
            }
            "bible_browser" => {
                let url = self.results.get(&_match_id).ok_or("err")?.urls[0].clone();
                let _ = webbrowser::open(&url);
            }
            _ => (),
        };
        Ok(())
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    Runner::new().start("com.jaanonim.bible_runner", "/bible_runner")?;
    Ok(())
}
