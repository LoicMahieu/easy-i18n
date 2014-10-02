
module.exports = (sequelize, DataTypes) ->
  sequelize.define "I18n",
    language:
      type: DataTypes.STRING
      allowNull: false
      validate:
        notEmpty: true

    key:
      type: DataTypes.STRING
      allowNull: false
      validate:
        notEmpty: true

    value:
      type: DataTypes.STRING(1000)

    namespace:
      type: DataTypes.STRING
      allowNull: false
      validate:
        notEmpty: true

    used:
      type: DataTypes.BIGINT
      defaultValue: 0