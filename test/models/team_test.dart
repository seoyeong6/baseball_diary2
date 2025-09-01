import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baseball_diary2/models/team.dart';

void main() {
  group('Team Model Tests', () {
    const testTeam = Team(
      id: 1,
      name: 'LG 트윈스',
      logoPath: 'assets/images/teams/lg_twins.png',
      primaryColor: Color(0xFFC30452),
    );

    test('should create Team instance with required fields', () {
      expect(testTeam.id, 1);
      expect(testTeam.name, 'LG 트윈스');
      expect(testTeam.logoPath, 'assets/images/teams/lg_twins.png');
    });

    test('should convert Team to JSON correctly', () {
      final json = testTeam.toJson();
      
      expect(json, {
        'id': 1,
        'name': 'LG 트윈스',
        'logoPath': 'assets/images/teams/lg_twins.png',
        'primaryColor': 0xFFC30452,
      });
    });

    test('should create Team from JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'LG 트윈스',
        'logoPath': 'assets/images/teams/lg_twins.png',
        'primaryColor': 0xFFC30452,
      };

      final team = Team.fromJson(json);

      expect(team.id, 1);
      expect(team.name, 'LG 트윈스');
      expect(team.logoPath, 'assets/images/teams/lg_twins.png');
    });

    test('should handle JSON serialization round trip', () {
      final json = testTeam.toJson();
      final recreatedTeam = Team.fromJson(json);

      expect(recreatedTeam.id, testTeam.id);
      expect(recreatedTeam.name, testTeam.name);
      expect(recreatedTeam.logoPath, testTeam.logoPath);
    });

    test('should implement equality correctly', () {
      const team1 = Team(id: 1, name: 'LG 트윈스', logoPath: 'path', primaryColor: Colors.red);
      const team2 = Team(id: 1, name: 'Other Name', logoPath: 'other_path', primaryColor: Colors.blue);
      const team3 = Team(id: 2, name: 'LG 트윈스', logoPath: 'path', primaryColor: Colors.red);

      expect(team1 == team2, true); // Same ID
      expect(team1 == team3, false); // Different ID
    });

    test('should implement hashCode correctly', () {
      const team1 = Team(id: 1, name: 'LG 트윈스', logoPath: 'path', primaryColor: Colors.red);
      const team2 = Team(id: 1, name: 'Other Name', logoPath: 'other_path', primaryColor: Colors.blue);

      expect(team1.hashCode, team2.hashCode); // Same ID, same hashCode
    });

    test('should have proper toString representation', () {
      final toString = testTeam.toString();
      
      expect(toString, contains('Team{'));
      expect(toString, contains('id: 1'));
      expect(toString, contains('name: LG 트윈스'));
      expect(toString, contains('logoPath: assets/images/teams/lg_twins.png'));
    });
  });

  group('KBOTeams Tests', () {
    test('should have 10 teams', () {
      expect(KBOTeams.teams.length, 10);
    });

    test('should find team by ID', () {
      final team = KBOTeams.getTeamById(1);
      
      expect(team, isNotNull);
      expect(team!.id, 1);
      expect(team.name, 'LG 트윈스');
    });

    test('should return null for invalid team ID', () {
      final team = KBOTeams.getTeamById(99);
      expect(team, isNull);
    });

    test('should find team by name', () {
      final team = KBOTeams.getTeamByName('LG 트윈스');
      
      expect(team, isNotNull);
      expect(team!.id, 1);
      expect(team.name, 'LG 트윈스');
    });

    test('should return null for invalid team name', () {
      final team = KBOTeams.getTeamByName('Invalid Team');
      expect(team, isNull);
    });

    test('should return all teams as unmodifiable list', () {
      final teams = KBOTeams.getAllTeams();
      
      expect(teams.length, 10);
      expect(() => teams.add(const Team(id: 11, name: 'Test', logoPath: 'test', primaryColor: Colors.green)),
          throwsUnsupportedError);
    });

    test('should have unique team IDs', () {
      final ids = KBOTeams.teams.map((team) => team.id).toList();
      final uniqueIds = ids.toSet();
      
      expect(ids.length, uniqueIds.length);
    });

    test('should have unique team names', () {
      final names = KBOTeams.teams.map((team) => team.name).toList();
      final uniqueNames = names.toSet();
      
      expect(names.length, uniqueNames.length);
    });

    test('should have valid logo paths for all teams', () {
      for (final team in KBOTeams.teams) {
        expect(team.logoPath, isNotEmpty);
        expect(team.logoPath, startsWith('lib/assets/images/teams/'));
        expect(team.logoPath, endsWith('.png'));
      }
    });
  });
}