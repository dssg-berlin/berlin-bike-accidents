import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.core.Coordinate;
import java.util.List;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import de.fhpotsdam.unfolding.providers.*;

class DarkMatterNoLabels extends AbstractMapTileUrlProvider {
        public DarkMatterNoLabels() {
            super(new MercatorProjection(26, new Transformation(1.068070779e7, 0.0, 3.355443185e7, 0.0,
                    -1.068070890e7, 3.355443057e7)));
        }

        public String getZoomString(Coordinate coordinate) {
            return (int) coordinate.zoom + "/" + (int) coordinate.column + "/" + (int) coordinate.row;
        }

        public int tileWidth() {
            return 256;
        }

        public int tileHeight() {
            return 256;
        }

        public String[] getTileUrls(Coordinate coordinate) {
            String url = "http://a.basemaps.cartocdn.com/dark_nolabels/" + getZoomString(coordinate) + ".png";
            return new String[] { url };
        }
    }


Calendar cal = Calendar.getInstance();
SimpleDateFormat format = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss", Locale.ENGLISH);

UnfoldingMap map;
MarkerManager markerManager;
List<Accident> markers = new ArrayList<Accident>();
Date start = new Date(1375315200000L);
Date originalStart = new Date(1375315200000L);
Date end = new Date(1377993600000L);
List<Feature> accidents;

color colorFatal = color(0xCC, 0x00, 0x00, 255);
color colorNoInjured = color(0xFF, 0xA5, 0x00, 255);
color colorNonFatalLight = color(0xF0, 0x7C, 0x00, 255);
color colorNonFatalSevere = color(0xDE, 0x50, 0x00, 255);

// Clock
SimpleDateFormat hour = new SimpleDateFormat("HH:mm", Locale.GERMAN);
SimpleDateFormat day = new SimpleDateFormat("dd. MMMM YYYY", Locale.GERMAN);
SimpleDateFormat weekday = new SimpleDateFormat("EEEE", Locale.GERMAN);
PFont raleway  = createFont("Roboto-Heavy", 36);
PFont raleway2  = createFont("Roboto-Bold", 24);
PImage clock; 
PImage calendar;

void setup() {
  size(1920, 1080, OPENGL);
  smooth();
  cal.setTime(start); // sets calendar time/date
  //cal.add(Calendar.HOUR_OF_DAY, 1); // adds one hour
  start=cal.getTime(); // returns new date object, one hour in the future
  map = new UnfoldingMap(this, new DarkMatterNoLabels());
  markerManager = map.getDefaultMarkerManager();
  map.zoomAndPanTo(new Location(52.4599658385934, 13.4459733089035), 13);
  MapUtils.createDefaultEventDispatcher(this, map);

  accidents = GeoJSONReader.loadData(this, "accidents.geojson");

  // Filter accidents
  Iterator<Feature> iter = accidents.iterator();
  int removed = 0;
  while(iter.hasNext()) {
    Feature feature = iter.next();
    Date datetime = parseDate(feature.getStringProperty("datetime"));
    if(datetime.before(start) || datetime.after(end)) {
        iter.remove();
        removed++;
    }
  }
  println("removed total: " + removed);
/*
  while(iter.hasNext()) {
    Feature feature = iter.next();
    Date datetime = parseDate(feature.getStringProperty("datetime"));
    if(datetime.before(start)) 
        start = datetime;
  }*/

  clock = loadImage("clock.png");
  calendar = loadImage("calendar.png");

  // Create markers from features, and use LINE property to color the markers.
  map.draw();
}

void draw() {
  if(millis() < 5000) {
    map.draw();
    return;
  } 
  
  if(millis()<10000) {
    map.draw();
    saveFrame("frames/frame-######.png");
    return;
  }
  
  if (start.before(end)) {

    Iterator<Accident> i = markers.iterator();
    while(i.hasNext()) {
        Accident a = i.next();
        if(a.canRemove()) {
            markerManager.removeMarker(a);
            i.remove();
        }
    }

    Iterator<Feature> featureIter = accidents.iterator();
    while(featureIter.hasNext()) {
        Feature feature = featureIter.next();
        Date datetime = parseDate(feature.getStringProperty("datetime"));

        if (datetime.before(start)) {
          PointFeature pointFeature = (PointFeature) feature;

  //Accident(Location location, Date timestamp, int beteiligte, int leichtverl, int schwerverl, int getoetete) {
          Accident a = new Accident(
            pointFeature.getLocation(),
            datetime,
            (Integer) feature.getProperty("beteiligte"),
            (Integer) feature.getProperty("leichtverl"),
            (Integer) feature.getProperty("schwerverl"),
            (Integer) feature.getProperty("getoetete")
          );


          featureIter.remove();

          markers.add(a);
          markerManager.addMarker(a);
        }
      }
    } else {
        exit();
    }
    start = new Date(start.getTime() + TimeUnit.HOURS.toMillis(1));
    
    fill(255, 255, 255, 255);
    map.draw();

    image(clock, 125 + 9 +  30, 800 - 2 + 30);
    stroke(232, 193, 2, 255);
    stroke(255, 255, 255, 255);
    line(125 - 3 + 30, 800 + 70, 125 + 13 + 170, 800 + 70);
    image(calendar, 125 + 6 +  30, 800 + 2 + 80 );
    textFont(raleway);
    noStroke();
    text(hour.format(start), 125 + 12 + 67, 800 + 55);
    textFont(raleway2);
    text(weekday.format(start), 125 + 80, 800 + 95);
    text(day.format(start), 125 + 80, 800  + 10 + 115);

    markerManager.draw();
    saveFrame("frames/frame-######.png");
}

public void keyPressed() {

  if (key == 'c') {
    markerManager.clearMarkers();
  }
}

Date parseDate(String dateString) {
    Date datetime = null;
        try {
          datetime = format.parse(dateString);
        }
        catch (ParseException e) {
          println("datetime");
          println(e);
        }

    return datetime;

}


class Accident extends SimplePointMarker {
  int beteiligte;
  int schwerverl, leichtverl, getoetete;

  Date timestamp;
  Date timestampEnd;

  Accident(Location location, Date timestamp, int beteiligte, int leichtverl, int schwerverl, int getoetete) {
    super(location);
    this.beteiligte = beteiligte;
    this.leichtverl = leichtverl;
    this.schwerverl = schwerverl;
    this.getoetete = getoetete;

    this.timestamp = timestamp;


    float noninjured = beteiligte - leichtverl - schwerverl - getoetete;
    float severity = (noninjured
        + leichtverl * 2
        + schwerverl * 6 
        + getoetete * 14) / 20.0;

    setStrokeWeight(0);
    setRadius(severity * 100);
    setColor(colorNoInjured);
    long showDuration = TimeUnit.DAYS.toMillis(1);

    if(leichtverl > 0) {
        setColor(colorNonFatalLight);
        //showDuration = TimeUnit.DAYS.toMillis(12);
    } 
    if(schwerverl> 0) {
        setColor(colorNonFatalSevere);
        //showDuration = TimeUnit.DAYS.toMillis(16);
    }

    if(getoetete > 0) {
        setColor(colorFatal);
        //showDuration = TimeUnit.DAYS.toMillis(22);
    }

    this.timestampEnd = new Date(timestamp.getTime() + showDuration);


    //color newColor = (c & 0xFFFFFF) | (((int) (severity * 255)) << 24);
    //setColor(newColor);
  }

  boolean canRemove() {
    return start.after(timestampEnd);
  }
}
